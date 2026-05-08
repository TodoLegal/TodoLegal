# frozen_string_literal: true

module Search
  # Groups flat ES search results into law→articles groups using first-seen positioning.
  #
  # Pure presentation logic — no DB queries, no ES queries, no side effects.
  # Receives flat results from UnifiedSearchService and returns a mixed array
  # of law_group and document entries that preserves ES relevance ordering.
  #
  # Algorithm (first-seen positioning):
  #   Walk results in ES score order. When the first article of a law is seen,
  #   create a law_group at that position. Subsequent articles of the same law
  #   are absorbed into the existing group (up to per_law cap). Documents stay
  #   at their original position.
  #
  # Example:
  #   Input:  [Art(law=15, score=0.95), Art(law=15, score=0.90), Doc(score=0.85), Art(law=1, score=0.80)]
  #   Output: [LawGroup(law=15, articles=[Art, Art]), Doc, LawGroup(law=1, articles=[Art])]
  #
  class ResultGrouper
    DEFAULT_PER_LAW = 10
    MAX_PER_LAW = 20

    def initialize(results_with_highlights, per_law: DEFAULT_PER_LAW)
      @results = results_with_highlights || []
      @per_law = (per_law.presence || DEFAULT_PER_LAW).to_i.clamp(1, MAX_PER_LAW)
    end

    def call
      output = []
      law_groups = {} # law_id => reference to the group hash in output

      @results.each do |source, highlights|
        if article?(source)
          law_id = source.law_id
          existing = law_groups[law_id]

          if existing
            # Absorb into existing group (if under per_law cap)
            existing[:articles] << [source, highlights] if existing[:articles].size < @per_law
          else
            # First article of this law — create group at this position
            group = { type: :law_group, law_id: law_id, articles: [[source, highlights]] }
            output << group
            law_groups[law_id] = group
          end
        else
          # Document — keep at original position
          output << { type: :document, source: source, highlights: highlights }
        end
      end

      output
    end

    def self.call(results_with_highlights, per_law: DEFAULT_PER_LAW)
      new(results_with_highlights, per_law: per_law).call
    end

    private

    def article?(source)
      source._index.to_s.start_with?('articles_')
    end
  end
end
