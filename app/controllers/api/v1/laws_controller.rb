class Api::V1::LawsController < Api::V1::BaseController
  skip_before_action :verify_turnstile_token!, only: [:search]

  def get_law
    @law = Law.find_by_id(params[:id])
    get_raw_law
    render json: { "law": @law, "stream": @stream }
  end

  # GET /api/v1/laws/search?query=pagos+jornada+trabajo
  # Authenticated via shared secret.
  # Expects keyword-style queries (the calling chatbot LLM extracts keywords).
  def search
    log_search_request

    unless ENV['CHATBOT_API_ENABLED'] == 'true'
      log_search_response(:service_unavailable, 0)
      return render json: { error: 'Service unavailable' }, status: :service_unavailable
    end

    unless chatbot_secret_valid?
      log_search_response(:unauthorized, 0)
      return render json: { error: 'Unauthorized' }, status: :unauthorized
    end

    query = params[:query].to_s.strip
    if query.blank?
      log_search_response(:bad_request, 0)
      return render json: { error: 'query parameter is required' }, status: :bad_request
    end

    limit = (params[:limit] || 10).to_i.clamp(1, 50)
    per_law = (params[:per_law] || 10).to_i.clamp(1, 20)

    matching_articles = Article.search_by_body_trimmed(query)
                              .select(:id, :law_id, :number, :body)
                              .with_pg_search_highlight
                              .with_pg_search_rank
                              .limit(200)
                              .group_by(&:law_id)

    law_ids = matching_articles.keys.first(limit)
    laws = Law.where(id: law_ids).select(:id, :name, :creation_number, :status).index_by(&:id)

    total_articles = 0
    results = law_ids.filter_map do |law_id|
      law = laws[law_id]
      next unless law

      articles = matching_articles[law_id].first(per_law).map do |article|
        total_articles += 1
        {
          id: article.id,
          number: article.number&.strip,
          body: helpers.strip_tags(article.body),
          snippet: helpers.sanitize(article.pg_search_highlight, tags: %w[b]),
          rank: article.pg_search_rank
        }
      end

      {
        law: {
          id: law.id,
          name: law.name,
          creation_number: law.creation_number,
          status: law.status,
          url: "https://todolegal.app/leyes/#{law.friendly_url}"
        },
        articles: articles
      }
    end

    render json: { results: results, query: query, total_articles: total_articles }
    log_search_response(:ok, total_articles, query)
  end

  private

  def log_search_request
    Rails.logger.error "[ChatbotSearch] Request | IP: #{request.remote_ip} | Query: #{params[:query]} | UA: #{request.user_agent}"
  end

  def log_search_response(status, total_articles, query = nil)
    Rails.logger.error "[ChatbotSearch] Response | IP: #{request.remote_ip} | Status: #{status} | Query: #{query} | Results: #{total_articles}"
  end

  def chatbot_secret_valid?
    secret = ENV['CHATBOT_API_SECRET']
    header = request.headers['X-Chatbot-Secret']
    return false if secret.blank? || header.blank?

    ActiveSupport::SecurityUtils.secure_compare(header, secret)
  end
end