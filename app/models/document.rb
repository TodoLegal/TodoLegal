class Document < ApplicationRecord
  include PgSearch

  has_one_attached :original_file

  pg_search_scope :search_by_all,
                  against: [:name, :description],
                  ignoring: :accents,
                  using: {
                    tsearch: {
                      dictionary: "tl_config"
                    }
                  }
end
