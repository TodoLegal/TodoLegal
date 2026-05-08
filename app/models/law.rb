class Law < ApplicationRecord
  include PgSearch::Model

  belongs_to :law_access
  has_many :books, dependent: :destroy
  has_many :titles, dependent: :destroy
  has_many :chapters, dependent: :destroy
  has_many :sections, dependent: :destroy
  has_many :subsections, dependent: :destroy
  has_many :articles, dependent: :destroy
  has_many :law_modifications, dependent: :destroy
  has_many :issuer_law_tags, dependent: :destroy
  has_many :law_tags, dependent: :destroy
  has_many :tags, through: :law_tags
  has_many :law_hyperlinks
  
  # Nueva relación para obtener documentos que modifican esta ley
  has_many :modifying_documents, through: :law_modifications, source: :document

  # Fields that represent meaningful law content changes.
  # Used to guard after_commit callbacks against touch-only updates.
  #
  # Problem: Article belongs_to :law, touch: true causes every Article.create!
  # to update the law's updated_at, firing all on: :update callbacks. Without
  # this guard, creating N articles would enqueue N WarmLawManifestJob and
  # N ReindexLawArticlesJob — a cascade of unnecessary work.
  #
  # Solution: Use Rails' previous_changes (available in after_commit) to check
  # if any meaningful field actually changed. Touch-only updates only change
  # updated_at, which is not in these lists, so the callbacks are skipped.
  MEANINGFUL_FIELDS = %w[name creation_number status hierarchy].freeze

  # Warm manifest on create (always — it's a new law, cache needs priming)
  after_commit :warm_manifest_cache, on: :create
  # Warm manifest on update only if meaningful fields changed (not touch-only)
  after_commit :warm_manifest_cache_on_update, on: :update
  # Reindex articles only if denormalized fields changed (not touch-only)
  after_commit :enqueue_reindex_articles, on: :update

  # Enum para los estados de la ley
  enum status: {
    vigente: 'vigente',
    derogado: 'derogado'
  }

  # Method to check if the law has been repealed
  def repealed?
    status == 'derogado'
  end

  # Method to check if the law has been amended
  def amended?
    law_modifications.where(modification_type: 'amend').exists?
  end

  # Method to get all amendments to the law
  def amendments
    law_modifications.where(modification_type: 'amend')
  end

  # Method to get the repeal of the law (if it exists)
  def repeal
    law_modifications.find_by(modification_type: 'repeal')
  end

  pg_search_scope :search_by_name,
                  against: [:name, :creation_number],
                  ignoring: :accents,
                  using: {
                    tsearch: {
                      dictionary: "spanish",
                      highlight: {
                        StartSel: '<b style="color:red" class="highlighted">',
                        StopSel: '</b>',
                        MaxWords: 123,
                        MinWords: 456,
                        ShortWord: 4,
                        HighlightAll: true,
                        MaxFragments: 3,
                        FragmentDelimiter: '&hellip;'
                      }
                    }
                  }

  def to_param
    friendly_url
  end
  
  def friendly_url
    [id, name.parameterize].join('-')
  end

  # Add scope for preloading
  scope :with_tags, -> { 
    includes(law_tags: { tag: :tag_type })
  }

  def materias
    if law_tags.loaded?
      # Use preloaded associations when available
      materia_tag_type = TagType.materia  # Use cached version
      return [] unless materia_tag_type
      law_tags.select { |lt| lt.tag&.tag_type_id == materia_tag_type.id }.map(&:tag).compact
    else
      # Fallback to original query when not preloaded
      Rails.logger.warn "Law#materias called without preloaded associations for Law ID: #{id}"
      materia_tag_type = TagType.materia  # Use cached version
      return [] unless materia_tag_type
      @materias ||= tags.where(tag_type_id: materia_tag_type.id)
    end
  end

  def materia_names
    if law_tags.loaded?
      # Use preloaded associations to avoid N+1 queries
      materia_tag_type = TagType.materia  # Use cached version
      return [] unless materia_tag_type
      @materia_names ||= law_tags.select { |lt| lt.tag&.tag_type_id == materia_tag_type.id }
                                .map { |lt| lt.tag&.name }
                                .compact
    else
      # Fallback to original implementation with warning
      Rails.logger.warn "Law#materia_names called without preloaded associations for Law ID: #{id}"
      @materia_names ||= materias.pluck(:name)
    end
  end

  def cached_books_count
    Rails.cache.fetch([self, "books_count"]) { books.size }
  end

  def cached_titles_count
    Rails.cache.fetch([self, "titles_count"]) { titles.size }
  end

  def cached_chapters_count
    Rails.cache.fetch([self, "chapters_count"]) { chapters.size }
  end

  def cached_sections_count
    Rails.cache.fetch([self, "sections_count"]) { sections.size }
  end

  def cached_subsections_count
    Rails.cache.fetch([self, "subsections_count"]) { subsections.size }
  end

  def cached_articles_count
    Rails.cache.fetch([self, "articles_count"]) { articles.size }
  end

  private

  # Warm manifest cache in background to avoid cold-cache penalty for users
  def warm_manifest_cache
    WarmLawManifestJob.perform_later(id)
  end

  # Skip warming on touch-only updates (e.g. Article touch cascade).
  # previous_changes.keys will only contain updated_at for touch-only,
  # which is not in MEANINGFUL_FIELDS.
  def warm_manifest_cache_on_update
    return unless (previous_changes.keys & MEANINGFUL_FIELDS).any?
    warm_manifest_cache
  end

  # Subset of MEANINGFUL_FIELDS that are denormalized into Article.search_data.
  # When these change, articles must be reindexed in ES to reflect the new values.
  DENORMALIZED_FIELDS = %w[name creation_number status hierarchy].freeze

  # Only reindex articles when denormalized fields actually changed.
  # Skips touch-only updates to avoid N reindex jobs when loading N articles.
  def enqueue_reindex_articles
    return unless (previous_changes.keys & DENORMALIZED_FIELDS).any?
    ReindexLawArticlesJob.perform_later(id)
  end
end