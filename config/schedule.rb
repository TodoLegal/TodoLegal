# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

set :output, "/root/TodoLegal/log/cron_log.log"

# Sitemap regeneration - runs daily at 12 AM
every 1.day, at: '12:00 am' do
  rake "sitemap:daily_regenerate"
end

# every 5.minutes do
#   command "/root/TodoLegal/update_google_drive_doc.sh"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever
