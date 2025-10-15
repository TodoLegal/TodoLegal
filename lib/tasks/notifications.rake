namespace :notifications do
  desc "Reschedule notification jobs for all Pro users"
  task reschedule_pro_users: :environment do
    include ApplicationHelper
    
    dry_run = ENV['DRY_RUN'] == 'true'
    
    puts dry_run ? "DRY RUN: Simulating notification job rescheduling for Pro users..." : "Starting to reschedule notification jobs for Pro users..."
    puts "=" * 60
    
    pro_users = find_pro_users
    rescheduled_count = 0
    skipped_count = 0
    error_count = 0
    
    puts "Found #{pro_users.count} Pro users to process"
    if dry_run
      puts "DRY RUN MODE: No actual changes will be made"
    else
      puts "Jobs will be scheduled with 12-hour buffer + 30-minute intervals to minimize resource consumption"
    end
    puts "=" * 60
    
    job_delay_minutes = 0
    
    pro_users.find_each(batch_size: 30) do |user|
      begin
        result = reschedule_user_notifications(user, dry_run, job_delay_minutes)
        case result[:status]
        when :rescheduled
          rescheduled_count += 1
          delay_info = dry_run ? "" : " (scheduled in #{job_delay_minutes} minutes)"
          puts "✓ #{dry_run ? 'Would reschedule' : 'Rescheduled'} notifications for user ID: #{user.id}, Email: #{user.email}#{delay_info}"
          job_delay_minutes += 30 unless dry_run  # Increment delay for next job
        when :skipped
          skipped_count += 1
          puts "- Skipped user ID: #{user.id}, Email: #{user.email} (#{result[:reason]})"
        end
      rescue => e
        error_count += 1
        puts "✗ Error processing user ID: #{user.id}, Email: #{user.email}: #{e.message}"
        Rails.logger.error "Error rescheduling notifications for user #{user.id}: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
      end
    end
    
    puts "=" * 60
    puts "=== SUMMARY ==="
    puts "Total Pro users found: #{pro_users.count}"
    puts "Successfully rescheduled: #{rescheduled_count}"
    puts "Skipped: #{skipped_count}"
    puts "Errors: #{error_count}"
    unless dry_run
      if rescheduled_count > 0
        total_span_hours = (rescheduled_count - 1) * 0.5  # 30 minutes = 0.5 hours
        puts "Jobs staggered over #{total_span_hours} hours (30-minute intervals)"
      end
    end
    puts "Task completed!"
    puts "=" * 60
  end
  
  private
  
  def find_pro_users
    # Users with active Stripe subscriptions (not just customer IDs)
    all_stripe_users = User.where.not(stripe_customer_id: [nil, ''])
    active_stripe_user_ids = []
    
    all_stripe_users.each do |user|
      begin
        customer = Stripe::Customer.retrieve(user.stripe_customer_id)
        if current_user_plan_is_active(customer)
          active_stripe_user_ids << user.id
        end
      rescue => e
        Rails.logger.warn "Error checking Stripe subscription for user #{user.id}: #{e.message}"
      end
    end
    
    # Users with Pro or Admin permissions
    permission_user_ids = User.joins(:user_permissions)
                             .joins('JOIN permissions ON permissions.id = user_permissions.permission_id')
                             .where('permissions.name IN (?)', ['Pro', 'Admin'])
                             .pluck(:id)
    
    # Combine both queries and return users with necessary associations preloaded
    all_pro_user_ids = (active_stripe_user_ids + permission_user_ids).uniq
    
    User.where(id: all_pro_user_ids)
        .includes(:users_preference, :user_trial, :permissions, :user_permissions)
  end
  
  def reschedule_user_notifications(user, dry_run = false, delay_minutes = 0)
    # Double-check if user is actually a Pro user
    unless is_pro_user?(user)
      return { status: :skipped, reason: "Not a Pro user" }
    end
    
    # Find or create user preferences
    user_preferences = UsersPreference.find_by(user_id: user.id)
    unless user_preferences
      if dry_run
        puts "  Would create preferences for user ID: #{user.id}, Email: #{user.email}"
      else
        user_preferences = create_preferences(user)
        puts "  Created preferences for user ID: #{user.id}, Email: #{user.email}"
      end
      return { status: :rescheduled } if dry_run
    end
    
    # Skip if notifications are disabled
    unless user_preferences.active_notifications
      return { status: :skipped, reason: "Notifications disabled" }
    end
    
    if dry_run
      puts "  Would reschedule job for user ID: #{user.id}, Email: #{user.email}"
      puts "  Current job ID: #{user_preferences.job_id || 'None'}"
      return { status: :rescheduled }
    end
    
    # Cancel existing job if any
    if user_preferences.job_id.present?
      deleted = delete_user_notifications_job(user_preferences.job_id)
      puts "  Deleted existing job (#{user_preferences.job_id}): #{deleted ? 'Success' : 'Failed/Not found'}"
    end
    
    # Schedule new job with staggered delay
    enqueue_new_job_with_delay(user, delay_minutes)
    user_preferences.reload
    total_delay_hours = (user_preferences.mail_frequency * 24) + 12 + (delay_minutes / 60.0)
    puts "  Enqueued new job with ID: #{user_preferences.job_id} (total delay: #{total_delay_hours.round(1)} hours)"
    
    { status: :rescheduled }
  end
  
  def is_pro_user?(user)
    # Check Stripe subscription first (most reliable indicator)
    if user.stripe_customer_id.present?
      begin
        customer = Stripe::Customer.retrieve(user.stripe_customer_id)
        return true if current_user_plan_is_active(customer)
      rescue Stripe::InvalidRequestError => e
        Rails.logger.warn "Invalid Stripe customer #{user.stripe_customer_id} for user #{user.id}: #{e.message}"
      rescue => e
        Rails.logger.error "Stripe API error for user #{user.id}: #{e.message}"
      end
    end
    
    # Fallback to permissions check
    user.permissions.where(name: ['Pro', 'Admin']).exists?
  end
  
  def enqueue_new_job_with_delay(user, delay_minutes)
    @user_preferences = UsersPreference.find_by(user_id: user.id)
    
    # Calculate the actual delay: user's frequency + 12 hours buffer + staggering delay
    total_delay = @user_preferences.mail_frequency.days + 12.hours + delay_minutes.minutes
    
    job = MailUserPreferencesJob.set(wait: total_delay).perform_later(user)
    @user_preferences.job_id = job.provider_job_id
    @user_preferences.save
  end
end