# frozen_string_literal: true

module Notifications
  class UserPreferencesPreview
    DEFAULT_LOOKBACK_DAYS = 45
    DEFAULT_UPDATED_BEFORE_MINUTES = 20
    DEFAULT_LIMIT = 25

    Result = Struct.new(
      :sendable,
      :reasons,
      :docs,
      :meta,
      keyword_init: true
    )

    def self.call(user_email:, lookback_days: DEFAULT_LOOKBACK_DAYS, updated_before_minutes: DEFAULT_UPDATED_BEFORE_MINUTES, limit: DEFAULT_LIMIT)
      new(
        user_email: user_email,
        lookback_days: lookback_days,
        updated_before_minutes: updated_before_minutes,
        limit: limit
      ).call
    end

    def initialize(user_email:, lookback_days:, updated_before_minutes:, limit:)
      @user_email = user_email
      @lookback_days = lookback_days
      @updated_before_minutes = updated_before_minutes
      @limit = limit
    end

    def call
      reasons = []

      normalized_email = @user_email.to_s.strip.downcase
      user = User.find_by('LOWER(email) = ?', normalized_email)
      return Result.new(sendable: false, reasons: ["User not found"], docs: [], meta: { user_email: normalized_email }) unless user

      preferences = UsersPreference.find_by(user_id: user.id)
      return Result.new(sendable: false, reasons: ["User has no UsersPreference record"], docs: [], meta: base_meta(user, preferences)) unless preferences

      unless safe_can_access_documents?(user)
        reasons << "User cannot access documents (trial inactive / not Pro)"
      end

      unless preferences.active_notifications
        reasons << "User has notifications disabled (users_preferences.active_notifications=false)"
      end

      tag_ids = Array(preferences.user_preference_tags).compact.uniq
      if tag_ids.empty?
        reasons << "User has no selected preference tags (users_preferences.user_preference_tags is empty)"
        return Result.new(sendable: false, reasons: reasons, docs: [], meta: base_meta(user, preferences))
      end

      institution_tag_type_id = TagType.find_by(name: "Institución")&.id
      mercantil_tag_id = Tag.find_by(name: "Mercantil")&.id

      time_window_start = (Date.today - @lookback_days.days).to_datetime
      updated_before = DateTime.now - @updated_before_minutes.minutes

      missing_tag_ids = []
      candidates = []
      candidates_without_updated_guard = []

      tag_ids.each do |tag_id|
        tag = Tag.find_by(id: tag_id)
        unless tag
          missing_tag_ids << tag_id
          next
        end

        # If tag is Institución type, query documents from issuer_document_tags only
        if institution_tag_type_id && tag.tag_type_id == institution_tag_type_id
          scope = Document.joins(:issuer_document_tags)
            .select(:id, :tag_id, :name, :issue_id, :publication_number, :publication_date, :description, :url)
            .where('publication_date > ?', time_window_start)
            .where('issuer_document_tags.tag_id' => tag_id)

          candidates_without_updated_guard.concat(scope.to_a)

          scope = scope.where('documents.updated_at <= ?', updated_before)
          candidates.concat(scope.to_a)
        else
          scope = Document.joins(:document_tags)
            .select(:id, :tag_id, :name, :issue_id, :publication_number, :publication_date, :description, :url)
            .where('publication_date > ?', time_window_start)
            .where('document_tags.tag_id' => tag_id)

          # If tag is Mercantil, discard documents that are Marcas de Fábrica
          if mercantil_tag_id && tag.id == mercantil_tag_id
            scope = scope.where("name NOT LIKE '%Marcas de Fábrica%'")
          end

          candidates_without_updated_guard.concat(scope.to_a)

          scope = scope.where('documents.updated_at <= ?', updated_before)
          candidates.concat(scope.to_a)
        end
      end

      candidates = candidates.uniq { |doc| doc.id }.sort_by { |doc| doc.publication_date || Time.at(0) }
      raw_candidate_count = candidates.length

      history = UserNotificationsHistory.find_by(user_id: user.id)
      sent_ids = Array(history&.documents_ids).compact

      after_history = candidates.reject { |doc| sent_ids.include?(doc.id) }
      after_history_count = after_history.length

      limited = after_history.first(@limit).uniq { |doc| doc.id }

      if missing_tag_ids.any?
        reasons << "Some selected tags no longer exist: #{missing_tag_ids.sort.join(', ')}"
      end

      if raw_candidate_count == 0
        # Detect if the only issue is the updated_at guard.
        any_without_updated_guard = candidates_without_updated_guard.uniq { |doc| doc.id }.any?
        if any_without_updated_guard
          reasons << "There are matching documents, but they were updated within the last #{@updated_before_minutes} minutes (documents.updated_at guard)"
        else
          reasons << "No documents matched selected tags in last #{@lookback_days} days"
        end
      elsif after_history_count == 0
        reasons << "All matching documents were already sent previously (history contains all candidate ids)"
      elsif limited.empty?
        reasons << "No documents remain after applying filters"
      end

      docs = attach_tag_names_and_issuer_tags(limited)

      sendable = reasons.empty? && docs.any?

      Result.new(
        sendable: sendable,
        reasons: reasons,
        docs: docs,
        meta: base_meta(user, preferences).merge(
          lookback_days: @lookback_days,
          updated_before_minutes: @updated_before_minutes,
          limit: @limit,
          selected_tag_ids_count: tag_ids.length,
          raw_candidate_count: raw_candidate_count,
          after_history_count: after_history_count,
          history_sent_ids_count: sent_ids.length
        )
      )
    end

    private

    def base_meta(user, preferences)
      {
        user_id: user&.id,
        user_email: user&.email,
        preferences_present: !preferences.nil?,
        preferences_active_notifications: preferences&.active_notifications
      }
    end

    # Mirrors ApplicationHelper#can_access_documents but avoids Stripe calls and side effects.
    def safe_can_access_documents?(user)
      return false unless user

      # Pro / editor / admin users can access.
      return true if user.permissions&.exists?(name: ['Pro', 'Editor', 'Admin', 'Editor D2', 'Editor TL'])

      # Basic users can access only if trial is active.
      trial = UserTrial.find_by(user_id: user.id)
      trial&.active? || false
    rescue StandardError
      false
    end

    def attach_tag_names_and_issuer_tags(documents)
      return [] if documents.blank?

      doc_ids = documents.map(&:id)

      issuer_tag_ids_by_doc = IssuerDocumentTag.where(document_id: doc_ids)
        .pluck(:document_id, :tag_id)
        .group_by { |(document_id, _tag_id)| document_id }
        .transform_values { |pairs| pairs.map { |(_, tag_id)| tag_id }.uniq }

      all_issuer_tag_ids = issuer_tag_ids_by_doc.values.flatten.uniq
      issuer_tag_names_by_id = Tag.where(id: all_issuer_tag_ids).pluck(:id, :name).to_h

      # Note: documents coming from .select include a tag_id column from join.
      tag_ids = documents.map { |d| d.respond_to?(:tag_id) ? d.tag_id : nil }.compact.uniq
      tag_names_by_id = Tag.where(id: tag_ids).pluck(:id, :name).to_h

      documents.map do |doc|
        issuer_names = Array(issuer_tag_ids_by_doc[doc.id]).map { |tid| issuer_tag_names_by_id[tid] }.compact

        {
          id: doc.id,
          name: doc.name,
          publication_date: doc.publication_date,
          issue_id: doc.try(:issue_id),
          publication_number: doc.try(:publication_number),
          url: doc.try(:url),
          tag_id: doc.try(:tag_id),
          tag_name: tag_names_by_id[doc.try(:tag_id)],
          issuer_tags: issuer_names
        }
      end
    end
  end
end
