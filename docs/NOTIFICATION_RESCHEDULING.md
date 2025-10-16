# Notification Job Rescheduling Tasks

This document describes the rake tasks created to reschedule notification mailer jobs for Pro users after a Sidekiq job loss.

## Available Tasks

### 1. Main Rescheduling Task

```bash
rails notifications:reschedule_pro_users
```

**Description:** Reschedules notification jobs for all Pro users (users with active Stripe subscriptions or Admin/Pro permissions). Jobs are scheduled with 30-minute staggering intervals between each user to minimize resource consumption. The user's mail frequency is handled by the notification system itself.

**What it does:**
- Identifies all Pro users (Stripe subscribers + Admin/Pro permission holders)
- Validates each user's Pro status
- Creates user preferences if missing
- Skips users with disabled notifications
- **Skips users who already have valid scheduled jobs in Sidekiq**
- Removes existing scheduled jobs (only for stale/invalid job IDs)
- Creates new notification jobs with 30-minute staggered delays (mail frequency handled by notification system)

### 2. Dry Run Mode

```bash
DRY_RUN=true rails notifications:reschedule_pro_users
```

**Description:** Simulates the rescheduling process without making actual changes. Use this to preview what the task will do.

### 3. Count Pro Users (Helper)

```bash
rails notifications:count_pro_users
```

**Description:** Provides statistics about Pro users and their notification preferences.

## Usage Examples

### Basic Usage (Production)
```bash
# In production environment
RAILS_ENV=production rails notifications:reschedule_pro_users
```

### Preview Changes First
```bash
# Check current Pro user count
rails notifications:count_pro_users

# Preview what would be changed
DRY_RUN=true rails notifications:reschedule_pro_users

# Execute the actual rescheduling
rails notifications:reschedule_pro_users
```

### Development Environment
```bash
rails notifications:reschedule_pro_users
```

## Pro User Identification Logic

The task identifies Pro users based on two criteria:

1. **Stripe Subscribers:** Users with `stripe_customer_id` field populated and active subscriptions
2. **Permission-Based:** Users with "Admin" or "Pro" permissions in the user_permissions table

The task combines both groups and removes duplicates for comprehensive coverage.

## Task Behavior

### Processing Flow
1. **Query Pro Users:** Efficiently fetches users with necessary associations preloaded
2. **Batch Processing:** Processes users in batches of 100 to avoid memory issues
3. **Validation:** Double-checks Pro status for each user
4. **Preferences Handling:** Creates default preferences if missing
5. **Job Management:** Removes old jobs and creates new ones
6. **Error Handling:** Continues processing even if individual users fail
7. **Comprehensive Logging:** Detailed output for monitoring and debugging

### Output Format
```
Starting to reschedule notification jobs for Pro users...
============================================================
Found 4 Pro users to process
Jobs will be scheduled with 30-minute intervals to minimize resource consumption
============================================================
  Deleted existing job (f02dc41264d5a77fcfed8a96): Success
  Enqueued new job with ID: a1b2c3d4e5f6g7h8i9j0k1l2 (stagger delay: 0.0 hours)
✓ Rescheduled notifications for user: user@example.com (scheduled in 0 minutes)
  Enqueued new job with ID: b2c3d4e5f6g7h8i9j0k1l2m3 (stagger delay: 0.5 hours)
✓ Rescheduled notifications for user: user2@example.com (scheduled in 30 minutes)
- Skipped user: user3@example.com (Notifications disabled)
✗ Error processing user user4@example.com: Connection timeout
============================================================
=== SUMMARY ===
Total Pro users found: 4
Successfully rescheduled: 2
Skipped: 1
Errors: 1
Jobs staggered over 0.5 hours (30-minute intervals)
Task completed!
============================================================
```

## Safety Features

- **Dry Run Mode:** Preview changes before execution
- **Pro User Validation:** Double-checks user status before processing
- **Existing Job Cleanup:** Removes old jobs to prevent duplicates
- **Error Isolation:** Individual user failures don't stop the entire process
- **Comprehensive Logging:** All actions logged for audit trail
- **Batch Processing:** Memory-efficient processing for large user bases

## Performance Considerations

- Uses `find_each(batch_size: 30)` for memory efficiency
- Preloads associations with `includes()` to prevent N+1 queries
- **Staggers job scheduling with 30-minute intervals** to prevent resource spikes
- **Mail frequency handled by notification system** when jobs execute (not in initial delay)
- Processes users in small batches to avoid overwhelming Sidekiq
- Efficient database queries combining Stripe and permission-based users

## Error Handling

The task handles several types of errors gracefully:

- **Stripe API Errors:** Continues with permission-based checks
- **Missing User Preferences:** Automatically creates default preferences
- **Job Deletion Failures:** Logs warnings but continues processing
- **Database Errors:** Individual user failures are logged and skipped

## Monitoring

### Logs
- Rails logs: Detailed error information with stack traces
- Console output: Real-time progress and summary statistics
- Sidekiq logs: Job creation and scheduling information

### Verification
After running the task, verify results by:
1. Checking Sidekiq scheduled jobs count
2. Running the count task to verify processed users
3. Monitoring email delivery for Pro users

## Troubleshooting

### Common Issues

**No Pro users found:**
- Check Stripe integration configuration
- Verify user permissions are properly assigned
- Ensure users have `stripe_customer_id` populated

**Jobs not being created:**
- Verify Sidekiq is running and configured correctly
- Check `enqueue_new_job` helper method functionality
- Ensure user preferences have valid mail frequency settings

**Stripe API errors:**
- Check Stripe API key configuration
- Verify customer IDs are valid
- Monitor Stripe API rate limits

### Manual Verification
```bash
# Check specific user's job status
rails console
user = User.find_by(email: 'user@example.com')
preferences = user.users_preference
puts "Job ID: #{preferences.job_id}"
puts "Active notifications: #{preferences.active_notifications}"
puts "Mail frequency: #{preferences.mail_frequency}"
```

## Related Files

- **Main Task:** `/lib/tasks/notifications.rake`
- **Helper Task:** `/lib/tasks/notifications_helper.rake`
- **Helper Methods:** `/app/helpers/application_helper.rb` (enqueue_new_job, delete_user_notifications_job)
- **Job Class:** `/app/jobs/mail_user_preferences_job.rb`
- **Models:** `/app/models/user.rb`, `/app/models/users_preference.rb`