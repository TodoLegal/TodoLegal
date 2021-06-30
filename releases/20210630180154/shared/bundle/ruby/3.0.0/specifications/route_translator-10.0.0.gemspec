# -*- encoding: utf-8 -*-
# stub: route_translator 10.0.0 ruby lib

Gem::Specification.new do |s|
  s.name = "route_translator".freeze
  s.version = "10.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/enriclluelles/route_translator/issues", "changelog_uri" => "https://github.com/enriclluelles/route_translator/blob/master/CHANGELOG.md", "source_code_uri" => "https://github.com/enriclluelles/route_translator" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Geremia Taglialatela".freeze, "Enric Lluelles".freeze, "Raul Murciano".freeze]
  s.date = "2021-01-16"
  s.description = "Translates the Rails routes of your application into the languages defined in your locale files".freeze
  s.email = ["tagliala.dev@gmail.com".freeze, "enric@lluell.es".freeze]
  s.homepage = "https://github.com/enriclluelles/route_translator".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.4".freeze)
  s.rubygems_version = "3.2.15".freeze
  s.summary = "Translate your Rails routes in a simple manner".freeze

  s.installed_by_version = "3.2.15" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<actionpack>.freeze, [">= 5.0.0.1", "< 6.2"])
    s.add_runtime_dependency(%q<activesupport>.freeze, [">= 5.0.0.1", "< 6.2"])
    s.add_runtime_dependency(%q<addressable>.freeze, ["~> 2.7"])
    s.add_development_dependency(%q<appraisal>.freeze, ["~> 2.3"])
    s.add_development_dependency(%q<byebug>.freeze, [">= 10.0", "< 12"])
    s.add_development_dependency(%q<coveralls_reborn>.freeze, ["~> 0.20.0"])
    s.add_development_dependency(%q<minitest>.freeze, ["~> 5.14"])
    s.add_development_dependency(%q<rails>.freeze, [">= 5.0.0.1", "< 6.2"])
    s.add_development_dependency(%q<rake>.freeze, ["~> 13.0"])
    s.add_development_dependency(%q<rubocop>.freeze, ["~> 1.8"])
    s.add_development_dependency(%q<rubocop-minitest>.freeze, ["~> 0.10.3"])
    s.add_development_dependency(%q<rubocop-performance>.freeze, ["~> 1.9"])
    s.add_development_dependency(%q<rubocop-rails>.freeze, ["~> 2.9"])
    s.add_development_dependency(%q<rubocop-rake>.freeze, ["~> 0.5.1"])
    s.add_development_dependency(%q<simplecov>.freeze, [">= 0.18.5", "< 0.22"])
  else
    s.add_dependency(%q<actionpack>.freeze, [">= 5.0.0.1", "< 6.2"])
    s.add_dependency(%q<activesupport>.freeze, [">= 5.0.0.1", "< 6.2"])
    s.add_dependency(%q<addressable>.freeze, ["~> 2.7"])
    s.add_dependency(%q<appraisal>.freeze, ["~> 2.3"])
    s.add_dependency(%q<byebug>.freeze, [">= 10.0", "< 12"])
    s.add_dependency(%q<coveralls_reborn>.freeze, ["~> 0.20.0"])
    s.add_dependency(%q<minitest>.freeze, ["~> 5.14"])
    s.add_dependency(%q<rails>.freeze, [">= 5.0.0.1", "< 6.2"])
    s.add_dependency(%q<rake>.freeze, ["~> 13.0"])
    s.add_dependency(%q<rubocop>.freeze, ["~> 1.8"])
    s.add_dependency(%q<rubocop-minitest>.freeze, ["~> 0.10.3"])
    s.add_dependency(%q<rubocop-performance>.freeze, ["~> 1.9"])
    s.add_dependency(%q<rubocop-rails>.freeze, ["~> 2.9"])
    s.add_dependency(%q<rubocop-rake>.freeze, ["~> 0.5.1"])
    s.add_dependency(%q<simplecov>.freeze, [">= 0.18.5", "< 0.22"])
  end
end
