# frozen_string_literal: true

class Api::V1::SearchController < Api::V1::BaseController
  skip_before_action :verify_turnstile_token!, only: [:search]
  before_action :doorkeeper_authorize!, only: [:search]
  skip_before_action :doorkeeper_authorize!, if: :service_secret_valid?

  # GET /api/v1/search
  #
  # Unified search across articles and gazette documents.
  # Results are served entirely from ES _source (load: false) — zero DB round-trips.
  #
  # Supports two formats:
  #   format=flat (default) — individual results in ES score order
  #   format=grouped — articles grouped by law (first-seen positioning) + documents flat
  def search
    search_per_page = params[:per_page]

    # In grouped mode, over-fetch from ES because article grouping collapses
    # multiple raw results into single law_group entries.
    if grouped_format? && search_per_page.present?
      @requested_per_page = search_per_page.to_i
      search_per_page = (search_per_page.to_i * 3).to_s
    end

    result = Search::UnifiedSearchService.call(
      query: params[:query],
      type: params[:type],
      filters: search_filters,
      page: params[:page],
      per_page: search_per_page
    )

    unless result.success?
      return render json: { error: result.error_message }, status: :service_unavailable
    end

    track_search(result.data[:total])

    if grouped_format?
      render_grouped(result)
    else
      render_flat(result)
    end
  end

  private

  def grouped_format?
    params[:result_format].to_s.downcase == 'grouped'
  end

  def render_flat(result)
    serialized = serialize_results(result.data[:results_with_highlights])

    render json: response_envelope(result, serialized)
  end

  def render_grouped(result)
    grouped = Search::ResultGrouper.call(
      result.data[:results_with_highlights],
      per_law: params[:per_law]
    )

    # Trim grouped output to the originally requested per_page
    per_page = @requested_per_page || result.data[:per_page]
    grouped = grouped.first(per_page)

    serialized = grouped.map do |entry|
      case entry[:type]
      when :law_group
        Search::GroupedLawSerializer.new(entry).serialize
      when :document
        Search::DocumentSerializer.new(
          entry[:source],
          highlights: entry[:highlights]
        ).serialize
      end
    end

    envelope = response_envelope(result, serialized)
    envelope[:per_page] = per_page
    render json: envelope
  end

  def response_envelope(result, serialized_results)
    {
      results: serialized_results,
      total: result.data[:total],
      page: result.data[:page],
      per_page: result.data[:per_page],
      total_pages: result.data[:total_pages],
      facets: result.data[:facets],
      metadata: result.data[:metadata]
    }
  end

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

  def serialize_results(results_with_highlights)
    results_with_highlights.map do |source, highlights|
      Search::BaseSerializer.for(source, highlights: highlights).serialize
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
      'format' => params[:result_format],
      'location' => 'API',
      'page' => params[:page],
      'per_page' => params[:per_page],
      'filters' => params[:filters]&.to_unsafe_h,
      'results' => total_count
    })
  rescue StandardError
    # Don't let analytics failures break search
  end

  # Allows chatbot and OG worker to bypass Doorkeeper via shared secrets.
  # Temporary: chatbot will migrate to Doorkeeper user auth soon.
  def service_secret_valid?
    chatbot_secret_valid? || og_worker_secret_valid?
  end

  def chatbot_secret_valid?
    secret = ENV['CHATBOT_API_SECRET']
    header = request.headers['X-Chatbot-Secret']
    return false if secret.blank? || header.blank?

    ActiveSupport::SecurityUtils.secure_compare(header, secret)
  end
end
