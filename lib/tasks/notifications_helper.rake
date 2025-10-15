namespace :notifications do
  desc "Count Pro users (for testing purposes)"
  task count_pro_users: :environment do
    include ApplicationHelper
    
    puts "Counting Pro users..."
    puts "=" * 40
    
    # Users with Stripe subscriptions (verify active plans)
    all_stripe_users = User.where.not(stripe_customer_id: [nil, ''])
    active_stripe_users = []
    stripe_errors = 0
    
    puts "Checking #{all_stripe_users.count} users with Stripe customer IDs..."
    
    all_stripe_users.each do |user|
      begin
        customer = Stripe::Customer.retrieve(user.stripe_customer_id)
        if current_user_plan_is_active(customer)
          active_stripe_users << user
        end
      rescue => e
        stripe_errors += 1
        puts "  Error checking Stripe for user #{user.email}: #{e.message}"
      end
    end
    
    puts "Users with Stripe customer ID: #{all_stripe_users.count}"
    puts "Users with ACTIVE Stripe plans: #{active_stripe_users.count}"
    if active_stripe_users.any?
      puts "  Active Stripe users:"
      active_stripe_users.each { |user| puts "    - #{user.email}" }
    end
    puts "Stripe API errors: #{stripe_errors}" if stripe_errors > 0
    
    # Users with Pro or Admin permissions
    permission_users = User.joins(:user_permissions)
                          .joins('JOIN permissions ON permissions.id = user_permissions.permission_id')
                          .where('permissions.name IN (?)', ['Pro', 'Admin'])
    puts "Users with Pro/Admin permissions: #{permission_users.count}"
    if permission_users.any?
      puts "  Permission-based Pro users:"
      permission_users.each { |user| puts "    - #{user.email}" }
    end
    
    # Combined (what the main task will process)
    active_stripe_user_ids = active_stripe_users.map(&:id)
    permission_user_ids = permission_users.pluck(:id)
    all_pro_user_ids = (active_stripe_user_ids + permission_user_ids).uniq
    
    puts "Combined unique Pro users: #{all_pro_user_ids.count}"
    puts "=" * 40
    
    # Break down by preferences status
    pro_users = User.where(id: all_pro_user_ids).includes(:users_preference)
    
    users_with_preferences = pro_users.joins(:users_preference)
    users_without_preferences = pro_users.left_outer_joins(:users_preference)
                                        .where(users_preferences: { id: nil })
    
    puts "Pro users with preferences: #{users_with_preferences.count}"
    if users_with_preferences.any?
      puts "  Users with preferences:"
      users_with_preferences.each { |user| puts "    - #{user.email}" }
    end
    
    puts "Pro users without preferences: #{users_without_preferences.count}"
    if users_without_preferences.any?
      puts "  Users without preferences:"
      users_without_preferences.each { |user| puts "    - #{user.email}" }
    end
    
    # Active notifications count
    users_with_active_notifications = pro_users.joins(:users_preference)
                                              .where(users_preferences: { active_notifications: true })
    puts "Pro users with active notifications: #{users_with_active_notifications.count}"
    if users_with_active_notifications.any?
      puts "  Users with active notifications:"
      users_with_active_notifications.each { |user| puts "    - #{user.email}" }
    end
    
    puts "=" * 40
    puts "Ready to reschedule #{users_with_active_notifications.count} notification jobs"
  end
end