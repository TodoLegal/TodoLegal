# config valid for current version and patch releases of Capistrano
require 'whenever/capistrano'

set :application, "TodoLegal"
set :repo_url, "https://github.com/TodoLegal/TodoLegal.git"
set :passenger_restart_command, '/usr/bin/passenger-config restart-app'
set :whenever_identifier, ->{ "#{fetch(:application)}_#{fetch(:stage)}" } # All cron jobs will have a consistent identifier 
set :whenever_command, "bundle exec whenever"
set :whenever_environment, -> { fetch(:rails_env, fetch(:stage)) }

append :linked_files, "config/master.key"
append :linked_files, "config/credentials.yml.enc"
append :linked_files, "gcs.keyfile"

namespace :deploy do
  namespace :check do
    before :linked_files, :set_master_key do
      on roles(:app), in: :sequence, wait: 10 do
        unless test("[ -f #{shared_path}/config/master.key ]")
            upload! 'config/master.key', "#{shared_path}/config/master.key"
        end
        unless test("[ -f #{shared_path}/config/credentials.yml.enc ]")
            upload! 'config/credentials.yml.enc', "#{shared_path}/config/credentials.yml.enc"
        end
        unless test("[ -f #{shared_path}/gcs.keyfile ]")
          upload! 'gcs.keyfile', "#{shared_path}/gcs.keyfile"
        end
      end
    end
  end
end


namespace :link_relic do
  desc 'Setup New Relic'
  task :link_relic do
    on roles(:web) do
      execute :ln, '-s /home/deploy/newrelic.yml /home/deploy/TodoLegal/current/config'
    end
  end
end

after "deploy", "link_relic:link_relic"

# after 'deploy:foo', 'deploy:link_relic'



namespace :debug do
  desc 'Print ENV variables'
  task :env do
    on roles(:app), in: :sequence, wait: 5 do
      execute :printenv
    end
  end
end







# Deploy to the user's home directory
set :deploy_to, "/home/deploy/#{fetch :application}"


append :linked_dirs, 'log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', '.bundle', 'public/system', 'public/uploads'

# Only keep the last 5 releases to save disk space
set :keep_releases, 5

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
# set :deploy_to, "/var/www/my_app_name"

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# append :linked_files, "config/database.yml"

# Default value for linked_dirs is []
# append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "public/system"

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for local_user is ENV['USER']
# set :local_user, -> { `git config user.name`.chomp }

# Default value for keep_releases is 5
# set :keep_releases, 5

# Uncomment the following to require manually verifying the host key before first deploy.
# set :ssh_options, verify_host_key: :secure
