# frozen_string_literal: true

class Api::V1::SearchController < Api::V1::BaseController
  skip_before_action :verify_turnstile_token!, only: [:search]
  before_action :doorkeeper_authorize!, only: [:search]
  skip_before_action :doorkeeper_authorize!, unless: :has_access_token?

  # GET /api/v1/search
  #
  # Unified search across laws, articles, and gazette documents.
  # Results are served from ES _source (load: false) — no DB round-trip
  # except for file_url on documents for paying/trial users.
  def search
    result = Search::UnifiedSearchService.call(
      query: params[:query],
      type: params[:type],
      filters: search_filters,
      page: params[:page],
      per_page: params[:per_page]
    )

    unless result.success?
      return render json: { error: result.error_message }, status: :service_unavailable
    end

    serialized_results = serialize_results(result.data[:results_with_highlights])

    track_search(result.data[:total])

    render json: {
      results: serialized_results,
      total: result.data[:total],
      page: result.data[:page],
      per_page: result.data[:per_page],
      total_pages: result.data[:total_pages],
      facets: result.data[:facets],
      metadata: result.data[:metadata]
    }
  end

  private

  def search_filters
    filters = {}
    if params[:filters].is_a?(ActionController::Parameters)
      filters[:status] = params[:filters][:status] if params[:filters][:status].present?
      filters[:tags] = params[:filters][:tags] if params[:filters][:tags].present?
      filters[:from] = params[:filters][:from] if params[:filters][:from].present?
      filters[:to] = params[:filters][:to] if params[:filters][:to].present?
    end
    filters
  end

  # Serializes ES _source results via per-type serializers.
  # For documents, batch-loads file_url from DB only for paying/trial users.
  def serialize_results(results_with_highlights)
    file_urls = batch_load_file_urls(results_with_highlights)

    results_with_highlights.map do |source, highlights|
      index = source._index.to_s
      if index.start_with?('documents_')
        Search::DocumentSerializer.new(
          source,
          highlights: highlights,
          file_url: file_urls[source.id]
        ).serialize
      else
        Search::BaseSerializer.for(source, highlights: highlights).serialize
      end
    end
  end

  # Batch-loads ActiveStorage file URLs for document results.
  # Only queries DB for paying/trial users. Returns empty hash otherwise.
  # 3 SQL queries total (documents + attachments + blobs) regardless of result count.
  def batch_load_file_urls(results_with_highlights)
    return {} unless can_access?

    doc_ids = results_with_highlights
      .select { |source, _| source._index.to_s.start_with?('documents_') }
      .map { |source, _| source.id }

    return {} if doc_ids.empty?

    documents = Document.where(id: doc_ids).with_attached_original_file.index_by(&:id)

    documents.each_with_object({}) do |(id, doc), urls|
      next unless doc.original_file.attached?

      urls[id] = Rails.application.routes.url_helpers.rails_blob_url(
        doc.original_file,
        disposition: 'attachment',
        only_path: true
      )
    end
  end

  def can_access?
    return @_can_access if defined?(@_can_access)

    @_can_access = if doorkeeper_token.present?
                     user = User.find_by_id(doorkeeper_token.resource_owner_id)
                     user ? can_access_documents(user) : false
                   else
                     false
                   end
  end

  def current_user_id
    return 0 unless doorkeeper_token.present?

    doorkeeper_token.resource_owner_id || 0
  end

  def track_search(total_count)
    return unless params[:query].present?

    $tracker.track(current_user_id, 'Unified Search', {
      'query' => params[:query],
      'type' => params[:type],
      'location' => 'API',
      'page' => params[:page],
      'per_page' => params[:per_page],
      'filters' => params[:filters]&.to_unsafe_h,
      'results' => total_count
    })
  rescue StandardError
    # Don't let analytics failures break search
  end

  def has_access_token?
    doorkeeper_token.present?
  end
end
