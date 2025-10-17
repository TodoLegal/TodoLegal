namespace :free_trial do
  desc "Deactivate expired user free trials"
  task deactivate_user_free_trial: :environment do
    include ApplicationHelper
    
    dry_run = ENV['DRY_RUN'] == 'true'
    puts dry_run ? "DRY RUN: Simulating deactivation of user free trials..." : "Starting deactivation of user free trials..."
    puts "=" * 60

    # Fix: Use database filtering instead of Ruby filtering
    users_with_expired_free_trial = UserTrial.includes(:user)
                                            .where(active: true)
                                            .where('trial_end <= ?', Date.current)

    puts "Found #{users_with_expired_free_trial.count} users with expired free trials to process"
    
    if users_with_expired_free_trial.any?
      puts "Expired trials:"
      users_with_expired_free_trial.each do |trial|
        puts "  - User ID: #{trial.user_id}, Email: #{trial.user&.email}, Trial ended: #{trial.trial_end}"
      end
    end
    
    puts "=" * 60

    deactivated_count = 0
    error_count = 0

    # Fix: Use find_each on ActiveRecord relation, not Array
    users_with_expired_free_trial.find_each(batch_size: 30) do |user_trial|
      begin
        if dry_run
          puts "DRY RUN: Would deactivate user ID: #{user_trial.user_id}, Email: #{user_trial.user&.email}"
          deactivated_count += 1
        else
          if user_trial.update(active: false)
            deactivated_count += 1
            puts "✓ Deactivated user ID: #{user_trial.user_id}, Email: #{user_trial.user&.email}"
          else
            error_count += 1
            puts "✗ Error deactivating user ID: #{user_trial.user_id}: #{user_trial.errors.full_messages.join(', ')}"
          end
        end
      rescue => e
        error_count += 1
        puts "✗ Exception deactivating user ID: #{user_trial.user_id}: #{e.message}"
        Rails.logger.error "Free trial deactivation error for user #{user_trial.user_id}: #{e.message}"
      end
    end

    puts "=" * 60
    puts "=== SUMMARY ==="
    puts "Total expired trials found: #{users_with_expired_free_trial.count}"
    puts "Successfully processed: #{deactivated_count}"
    puts "Errors: #{error_count}"
    puts "Task completed!"
  end
end