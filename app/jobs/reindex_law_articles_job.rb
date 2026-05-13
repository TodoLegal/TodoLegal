class ReindexLawArticlesJob < ApplicationJob
  queue_as :default

  def perform(law_id)
    law = Law.find_by(id: law_id)
    return unless law

    law.articles.reindex
  end
end
