#!/usr/bin/env ruby
# frozen_string_literal: true

# Service: Laws::ManifestBuilder
# Purpose: Build a hierarchical + flat manifest for a Law enabling O(1) navigation,
#          chunk prefetching, and search integration without DOM traversal.
# Output structure (Ruby hash convertible to JSON):
# {
#   law_id: Integer,
#   version: ISO8601 String (law updated_at),
#   chunking: { chunk_size: Integer, total_articles: Integer, total_pages: Integer },
#   structure: [ recursive container nodes ],
#   articles: [ { global_index, article_number, position, structure_path, chunk_page } ]
# }
# Each container node: { type, number, name, position, range:{first_article_index,last_article_index}, children:[...] }
# Assumptions:
# - Models provide `position` and `number` (if not, adapt builders).
# - Global article ordering is derived from `articles.order(:position)` (fallback to id if position absent).
# Performance considerations:
# - Single pass queries per model with minimal selected columns.
# - Range computation uses pre-grouped arrays rather than repeated queries.
# - Avoids N+1: all collections loaded upfront.
# - Can be cached (Rails.cache) keyed by law updated_at to invalidate on edits.

module Laws
  class ManifestBuilder
    # Unified chunk size: use LawDisplayConfig as single source of truth (normal context)
    # Avoid divergence with LawDisplayService / infinite scroll chunking.
    # Use LawDisplayConfig CHUNK_SIZES directly; class_methods from concern aren't available on module.
    # Fallback to 100 if constant not loaded to avoid runtime NameError breaking manifest build.
    DEFAULT_CHUNK_SIZE = (defined?(LawDisplayConfig::CHUNK_SIZES) && LawDisplayConfig::CHUNK_SIZES[:normal]) || 100

    # Build manifest for a given law.
    # Params:
    # law: Law instance
    # chunk_size: Integer (optional override)
    # Returns: Hash manifest
    def self.build(law, chunk_size: DEFAULT_CHUNK_SIZE)
      new(law, chunk_size: chunk_size).build
    end

    def initialize(law, chunk_size: DEFAULT_CHUNK_SIZE)
      @law = law
      @chunk_size = chunk_size
    end

    def build
      articles = load_articles
      containers = load_containers

      # Precompute article ranges per container type by position
      article_ranges = compute_article_ranges(articles, containers)
      structure_tree = build_hierarchy(containers, article_ranges)
      articles_index = build_articles_index(articles, structure_tree)

      {
        law_id: @law.id,
        version: @law.updated_at.utc.iso8601,
        chunking: chunking_metadata(articles.size),
        structure: structure_tree,
        articles: articles_index
      }
    end

    private

    # Load articles with minimal columns needed for manifest to reduce memory footprint.
    def load_articles
      @law.articles.select(:id, :body, :position, :number).order(:position) # body may be optional; include if needed for future features
    end

    # Load all structural containers; future: refine select columns.
    def load_containers
      {
        book:       @law.books.select(:id, :position, :number, :name).order(:position),
        title:      @law.titles.select(:id, :position, :number, :name).order(:position),
        chapter:    @law.chapters.select(:id, :position, :number, :name).order(:position),
        section:    @law.sections.select(:id, :position, :number, :name).order(:position),
        subsection: @law.subsections.select(:id, :position, :number, :name).order(:position)
      }
    end

    # Compute first/last article global indices for each container by scanning ordered articles once.
    # Returns: { type => { position => { first_article_index:, last_article_index: } } }
    def compute_article_ranges(articles, containers)
      ranges = Hash.new { |h, k| h[k] = {} }
      # Build a lookup from position ranges to container types if hierarchical positions are segment-based.
      # Simple approach: assign range if article.position falls between container.position and next container.position.
      # Here we assume articles carry enough info to correlate; if not, extend Article with foreign keys.

      # Fallback heuristic: nearest preceding container of each type.
      index_by_type = containers.transform_values { |rels| rels.to_a }
      pointers = Hash[index_by_type.keys.map { |t| [t, 0] }]

      articles.each_with_index do |article, global_index|
        index_by_type.each do |type, list|
          while pointers[type] + 1 < list.length && list[pointers[type] + 1].position <= article.position
            pointers[type] += 1
          end
          current_container = list[pointers[type]]
          next unless current_container # law may not have all container types
          pos = current_container.position
          bucket = (ranges[type][pos] ||= { first_article_index: global_index, last_article_index: global_index })
          bucket[:last_article_index] = global_index
        end
      end
      ranges
    end

    # Build recursive hierarchy: book > title > chapter > section > subsection.
    def build_hierarchy(containers, ranges)
      # Convert each relation set to hash keyed by position for O(1)
      by_type = containers.transform_values { |rels| rels.index_by(&:position) }

      # Sort positions for deterministic traversal
      books      = by_type[:book].keys.sort.map { |p| by_type[:book][p] }
      titles     = by_type[:title].keys.sort.map { |p| by_type[:title][p] }
      chapters   = by_type[:chapter].keys.sort.map { |p| by_type[:chapter][p] }
      sections   = by_type[:section].keys.sort.map { |p| by_type[:section][p] }
      subsections= by_type[:subsection].keys.sort.map { |p| by_type[:subsection][p] }

      # Helper to serialize a container record
      serialize = lambda do |rec, type|
        range = ranges[type][rec.position]
        {
          type: type.to_s,
          number: rec.number,
          name: rec.name,
          position: rec.position,
          range: range || { first_article_index: nil, last_article_index: nil },
          children: []
        }
      end

      # For now, naive nesting by position ordering: each lower level attaches to nearest preceding parent of higher level.
      attach = lambda do |parents, children|
        return if parents.empty? || children.empty?
        parent_ptr = 0
        children.each do |child|
          while parent_ptr + 1 < parents.length && parents[parent_ptr + 1][:position] <= child[:position]
            parent_ptr += 1
          end
          parents[parent_ptr][:children] << child
        end
      end

      book_nodes       = books.map { |b| serialize.call(b, :book) }
      title_nodes      = titles.map { |t| serialize.call(t, :title) }
      chapter_nodes    = chapters.map { |c| serialize.call(c, :chapter) }
      section_nodes    = sections.map { |s| serialize.call(s, :section) }
      subsection_nodes = subsections.map { |s| serialize.call(s, :subsection) }

      # Build hierarchy bottom-up (subsections attach to sections, etc.)
      attach.call(section_nodes, subsection_nodes)
      attach.call(chapter_nodes, section_nodes)
      attach.call(title_nodes, chapter_nodes)
      attach.call(book_nodes, title_nodes)

      # Return top-most non-empty level as root
      # This ensures laws without books still have a valid structure
      return book_nodes unless book_nodes.empty?
      return title_nodes unless title_nodes.empty?
      return chapter_nodes unless chapter_nodes.empty?
      return section_nodes unless section_nodes.empty?
      return subsection_nodes unless subsection_nodes.empty?
      []
    end

    # Build flat article index referencing structure path by positions only (names resolvable from structure tree).
    def build_articles_index(articles, structure_tree)
      # Build lookup maps for quick path resolution by position thresholds.
      all_nodes = flatten_tree(structure_tree)
      # Group nodes by type for efficient nearest predecessor lookup.
      nodes_by_type = all_nodes.group_by { |n| n[:type].to_sym }
      sorted_by_type = nodes_by_type.transform_values { |arr| arr.sort_by { |n| n[:position] } }

      pointers = Hash[sorted_by_type.keys.map { |t| [t, 0] }]

      articles.each_with_index.map do |article, idx|
        # Advance pointers to nearest preceding node per type
        sorted_by_type.each do |type, list|
          while pointers[type] + 1 < list.length && list[pointers[type] + 1][:position] <= article.position
            pointers[type] += 1
          end
        end
        structure_path = sorted_by_type.keys.sort_by { |t| precedence_index(t) }.map do |type|
          node = sorted_by_type[type][pointers[type]]
          next unless node
          { type: node[:type], position: node[:position] }
        end.compact
        {
          global_index: idx,
          article_number: article.number,
          position: article.position,
          chunk_page: (idx / @chunk_size) + 1,
          structure_path: structure_path
        }
      end
    end

    def flatten_tree(tree)
      result = []
      stack = tree.dup
      until stack.empty?
        node = stack.shift
        result << node
        stack.concat(node[:children]) if node[:children]&.any?
      end
      result
    end

    # Precedence for ordering structure path (top-down)
    def precedence_index(type)
      case type.to_sym
      when :book then 0
      when :title then 1
      when :chapter then 2
      when :section then 3
      when :subsection then 4
      else 99
      end
    end

    def chunking_metadata(total_articles)
      pages = (total_articles.to_f / @chunk_size).ceil
      { chunk_size: @chunk_size, total_articles: total_articles, total_pages: pages }
    end
  end
end
