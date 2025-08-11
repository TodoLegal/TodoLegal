class TagType < ApplicationRecord
  has_many :tags

  # Cache frequently accessed tag types to avoid N+1 queries
  def self.materia
    Rails.cache.fetch("tag_type_materia", expires_in: 1.hour) do
      find_by_name('materia')
    end
  end

  def self.cached_find_by_name(name)
    Rails.cache.fetch("tag_type_#{name}", expires_in: 1.hour) do
      find_by_name(name)
    end
  end
end
