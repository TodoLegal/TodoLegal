# -*- encoding: utf-8 -*-
# stub: discordrb-webhooks 3.3.0 ruby lib

Gem::Specification.new do |s|
  s.name = "discordrb-webhooks".freeze
  s.version = "3.3.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["meew0".freeze]
  s.bindir = "exe".freeze
  s.date = "2018-10-28"
  s.description = "A client for Discord's webhooks to fit alongside [discordrb](https://rubygems.org/gems/discordrb).".freeze
  s.email = ["".freeze]
  s.homepage = "https://github.com/meew0/discordrb".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.1.0".freeze)
  s.rubygems_version = "3.2.15".freeze
  s.summary = "Webhook client for discordrb".freeze

  s.installed_by_version = "3.2.15" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<rest-client>.freeze, [">= 2.1.0.rc1"])
  else
    s.add_dependency(%q<rest-client>.freeze, [">= 2.1.0.rc1"])
  end
end
