# frozen_string_literal: true

namespace :notifications do
  desc "Preview next user-preferences notification payload for a given user email (no email is sent, no history is modified)"
  task :preview_user_preferences, [:email] => :environment do |_t, args|
    email = args[:email].presence || ENV['EMAIL'].presence

    if email.blank?
      puts "Usage: bundle exec rake notifications:preview_user_preferences[user@example.com]"
      puts "   or: EMAIL=user@example.com bundle exec rake notifications:preview_user_preferences"
      exit(1)
    end

    result = Notifications::UserPreferencesPreview.call(user_email: email)

    meta_user_id = result.meta.fetch(:user_id, "n/a")
    meta_email = result.meta[:user_email].presence || email

    puts "User: #{meta_user_id} (#{meta_email})"
    puts "Preferences: present=#{result.meta.fetch(:preferences_present, false)} active_notifications=#{result.meta.fetch(:preferences_active_notifications, false)}"
    puts "Stats: selected_tags=#{result.meta.fetch(:selected_tag_ids_count, 0)} candidates=#{result.meta.fetch(:raw_candidate_count, 0)} after_history=#{result.meta.fetch(:after_history_count, 0)} history_sent_ids=#{result.meta.fetch(:history_sent_ids_count, 0)}"
    puts "Window: lookback_days=#{result.meta.fetch(:lookback_days, "?")} updated_before_minutes=#{result.meta.fetch(:updated_before_minutes, "?")} limit=#{result.meta.fetch(:limit, "?")}"

    if result.docs.any?
      puts "\nWould send #{result.docs.length} document(s) in the next notification:\n"
      result.docs.each_with_index do |doc, idx|
        issuer = doc[:issuer_tags].any? ? " | issuers: #{doc[:issuer_tags].join(', ')}" : ""
        tag = doc[:tag_name].present? ? "#{doc[:tag_name]}" : doc[:tag_id]

        puts format(
          "%<n>2d. [%<date>s] doc_id=%<id>d tag=%<tag>s%<issuer>s | %<name>s",
          n: idx + 1,
          date: (doc[:publication_date]&.to_date || "?").to_s,
          id: doc[:id],
          tag: tag,
          issuer: issuer,
          name: doc[:name].to_s
        )
      end
    else
      puts "\nNo documents would be sent in the next notification."
      if result.reasons.any?
        puts "Reasons:"
        result.reasons.each { |r| puts "- #{r}" }
      end
    end

    # Even if docs exist, show warnings/reasons (e.g., missing tags) if any.
    if result.docs.any? && result.reasons.any?
      puts "\nNotes:"
      result.reasons.each { |r| puts "- #{r}" }
    end
  end
end
