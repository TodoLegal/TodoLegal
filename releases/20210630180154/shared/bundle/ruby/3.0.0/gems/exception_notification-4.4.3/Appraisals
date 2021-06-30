# frozen_string_literal: true

rails_versions = ['~> 4.0.5', '~> 4.1.1', '~> 4.2.0', '~> 5.0.0', '~> 5.1.0', '~> 5.2.0', '~> 6.0.0']

rails_versions.each do |rails_version|
  appraise "rails#{rails_version.slice(/\d+\.\d+/).tr('.', '_')}" do
    gem 'rails', rails_version
  end
end
