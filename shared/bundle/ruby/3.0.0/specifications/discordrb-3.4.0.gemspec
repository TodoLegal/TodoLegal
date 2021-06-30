# -*- encoding: utf-8 -*-
# stub: discordrb 3.4.0 ruby lib

Gem::Specification.new do |s|
  s.name = "discordrb".freeze
  s.version = "3.4.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "changelog_uri" => "https://github.com/shardlab/discordrb/blob/master/CHANGELOG.md" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["meew0".freeze, "swarley".freeze]
  s.bindir = "exe".freeze
  s.date = "2020-12-06"
  s.description = "A Ruby implementation of the Discord (https://discord.com) API.".freeze
  s.email = ["".freeze]
  s.homepage = "https://github.com/shardlab/discordrb".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.5".freeze)
  s.rubygems_version = "3.2.15".freeze
  s.summary = "Discord API for Ruby".freeze

  s.installed_by_version = "3.2.15" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<ffi>.freeze, [">= 1.9.24"])
    s.add_runtime_dependency(%q<opus-ruby>.freeze, [">= 0"])
    s.add_runtime_dependency(%q<rest-client>.freeze, [">= 2.0.0"])
    s.add_runtime_dependency(%q<websocket-client-simple>.freeze, [">= 0.3.0"])
    s.add_runtime_dependency(%q<discordrb-webhooks>.freeze, ["~> 3.3.0"])
    s.add_development_dependency(%q<bundler>.freeze, [">= 1.10", "< 3"])
    s.add_development_dependency(%q<rake>.freeze, ["~> 13.0"])
    s.add_development_dependency(%q<redcarpet>.freeze, ["~> 3.5.0"])
    s.add_development_dependency(%q<rspec>.freeze, ["~> 3.10.0"])
    s.add_development_dependency(%q<rspec-prof>.freeze, ["~> 0.0.7"])
    s.add_development_dependency(%q<rubocop>.freeze, ["~> 1.4.0"])
    s.add_development_dependency(%q<rubocop-performance>.freeze, ["~> 1.0"])
    s.add_development_dependency(%q<simplecov>.freeze, ["~> 0.19.0"])
    s.add_development_dependency(%q<yard>.freeze, ["~> 0.9.9"])
  else
    s.add_dependency(%q<ffi>.freeze, [">= 1.9.24"])
    s.add_dependency(%q<opus-ruby>.freeze, [">= 0"])
    s.add_dependency(%q<rest-client>.freeze, [">= 2.0.0"])
    s.add_dependency(%q<websocket-client-simple>.freeze, [">= 0.3.0"])
    s.add_dependency(%q<discordrb-webhooks>.freeze, ["~> 3.3.0"])
    s.add_dependency(%q<bundler>.freeze, [">= 1.10", "< 3"])
    s.add_dependency(%q<rake>.freeze, ["~> 13.0"])
    s.add_dependency(%q<redcarpet>.freeze, ["~> 3.5.0"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.10.0"])
    s.add_dependency(%q<rspec-prof>.freeze, ["~> 0.0.7"])
    s.add_dependency(%q<rubocop>.freeze, ["~> 1.4.0"])
    s.add_dependency(%q<rubocop-performance>.freeze, ["~> 1.0"])
    s.add_dependency(%q<simplecov>.freeze, ["~> 0.19.0"])
    s.add_dependency(%q<yard>.freeze, ["~> 0.9.9"])
  end
end
