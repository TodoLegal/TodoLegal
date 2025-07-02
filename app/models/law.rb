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

  def materias
    @materias ||= tags.where(tag_type_id: TagType.find_by_name('materia').id)
  end

  def materia_names
    @materia_names ||= materias.pluck(:name)
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
end