#!/usr/bin/env ruby
# frozen_string_literal: true

# Laws::ManifestCache
# Responsibility: Provide cached subsets or full manifest for a Law.
# Keeps view templates thin by preparing data in controller/service layer.
# Caching keyed by law.id + law.updated_at ensures automatic invalidation on edits.

module Laws
  class ManifestCache
    INLINE_EXPIRES_IN = 12.hours
    FULL_EXPIRES_IN   = 6.hours

    # Returns inline subset used at initial render (structure + chunking metadata + version).
    def self.inline_subset(law)
      Rails.cache.fetch(inline_key(law), expires_in: INLINE_EXPIRES_IN) do
        manifest = Laws::ManifestBuilder.build(law)
        { law_id: manifest[:law_id], version: manifest[:version], chunking: manifest[:chunking], structure: manifest[:structure] }
      end
    end

    # Returns full manifest (includes articles index).
    def self.full(law)
      Rails.cache.fetch(full_key(law), expires_in: FULL_EXPIRES_IN) do
        Laws::ManifestBuilder.build(law)
      end
    end

    def self.inline_key(law)
      ["law-manifest-inline", law.id, law.updated_at.to_i]
    end

    def self.full_key(law)
      ["law-manifest-full", law.id, law.updated_at.to_i]
    end
  end
end
