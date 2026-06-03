# frozen_string_literal: true

module Documents
  # Generates a pre-signed GCS URL for downloading a document's original file.
  # Enforces access control, download rate limits, and tracks analytics before
  # returning a short-lived signed URL (expires in URL_EXPIRY = 5 minutes).
  #
  # Usage:
  #   result = Documents::DownloadService.call(document_id: 42, user: current_user)
  #   if result.success?
  #     result.data[:url]        # => "https://storage.googleapis.com/...signed..."
  #     result.data[:expires_at] # => "2026-06-03T12:05:00Z"
  #   else
  #     result.error_message     # => "Access denied" / "Download limit exceeded..." / etc.
  #     result.metadata[:status] # => :not_found / :forbidden / :too_many_requests
  #   end
  class DownloadService < ApplicationService
    include ApplicationHelper

    URL_EXPIRY = 5.minutes

    def initialize(document_id:, user:)
      @document_id = document_id
      @user = user
    end

    def call
      document = Document.find_by(id: @document_id)
      return failure(['Document not found'], status: :not_found) unless document
      return failure(['No file attached'], status: :not_found) unless document.original_file.attached?
      return failure(['Access denied'], status: :forbidden) unless can_access_documents(@user)

      user_type = current_user_type_api(@user)
      user_trial = @user.user_trial

      limit_result = enforce_download_limits(user_type, user_trial)
      return limit_result if limit_result

      increment_download_counters(user_type, user_trial)
      track_download(document, user_type)
      build_success_result(document)
    end

    private

    def enforce_download_limits(user_type, user_trial)
      return nil if user_type == "pro" || user_trial.nil?

      if user_trial.downloads >= MAXIMUM_TOTAL_TRIAL_DOWNLOADS
        Rails.logger.error "[DownloadAbuse] User #{@user.id} (#{@user.email}) exceeded total trial download limit (#{user_trial.downloads})"
        return failure(['Download limit exceeded. Please upgrade your plan.'], status: :too_many_requests)
      end

      daily_downloads = daily_download_count(@user)
      if daily_downloads >= MAXIMUM_DAILY_TRIAL_DOWNLOADS
        Rails.logger.error "[DownloadAbuse] User #{@user.id} (#{@user.email}) exceeded daily download limit (#{daily_downloads} today)"
        return failure(['Daily download limit exceeded. Please try again tomorrow or upgrade your plan.'], status: :too_many_requests)
      end

      nil
    end

    def increment_download_counters(user_type, user_trial)
      return unless user_trial

      if user_type != "pro"
        user_trial.increment!(:downloads)
        increment_daily_download_count(@user)
      elsif !@user.confirmed_at?
        user_trial.increment!(:downloads)
      end
    end

    def build_success_result(document)
      signed_url = document.original_file.url(expires_in: URL_EXPIRY, disposition: :inline)
      success({ url: signed_url, expires_at: URL_EXPIRY.from_now.iso8601 })
    end

    def track_download(document, user_type)
      document_type = "document"
      if document.document_type
        document_type = document.document_type.name.downcase.gsub(/\s+/, "-")
        document_type = remove_accents(document_type)
      end

      $tracker.track(@user.id, 'Valid download', {
        'user_type' => user_type,
        'document_name' => document.name,
        'document_id' => document.id,
        'location' => "API",
        'document_url' => "https://valid.todolegal.app/#{document_type}/honduras/#{document.url}/#{document.id}"
      })
    rescue StandardError => e
      Rails.logger.error "[DownloadService] Analytics tracking failed: #{e.message}"
    end

    def daily_download_count(user)
      redis = Redis.new(url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0'))
      key = "user_daily_downloads:#{user.id}:#{Date.current}"
      redis.get(key).to_i
    end

    def increment_daily_download_count(user)
      redis = Redis.new(url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0'))
      key = "user_daily_downloads:#{user.id}:#{Date.current}"
      redis.multi do |tx|
        tx.incr(key)
        tx.expire(key, 86_400)
      end
    end
  end
end
