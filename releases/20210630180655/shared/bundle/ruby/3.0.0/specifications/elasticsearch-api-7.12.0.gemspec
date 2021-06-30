# -*- encoding: utf-8 -*-
# stub: elasticsearch-api 7.12.0 ruby lib

Gem::Specification.new do |s|
  s.name = "elasticsearch-api".freeze
  s.version = "7.12.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/elastic/elasticsearch-ruby/issues", "changelog_uri" => "https://github.com/elastic/elasticsearch-ruby/blob/7.x/CHANGELOG.md", "homepage_uri" => "https://www.elastic.co/guide/en/elasticsearch/client/ruby-api/7.x/index.html", "source_code_uri" => "https://github.com/elastic/elasticsearch-ruby/tree/7.x/elasticsearch-api" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Karel Minarik".freeze]
  s.date = "2021-03-23"
  s.description = "Ruby API for Elasticsearch. See the `elasticsearch` gem for full integration.\n".freeze
  s.email = ["karel.minarik@elasticsearch.org".freeze]
  s.extra_rdoc_files = ["README.md".freeze, "LICENSE".freeze]
  s.files = ["LICENSE".freeze, "README.md".freeze]
  s.homepage = "https://www.elastic.co/guide/en/elasticsearch/client/ruby-api/7.x/index.html".freeze
  s.licenses = ["Apache-2.0".freeze]
  s.rdoc_options = ["--charset=UTF-8".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.4".freeze)
  s.rubygems_version = "3.2.15".freeze
  s.summary = "Ruby API for Elasticsearch.".freeze

  s.installed_by_version = "3.2.15" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<multi_json>.freeze, [">= 0"])
    s.add_development_dependency(%q<ansi>.freeze, [">= 0"])
    s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_development_dependency(%q<elasticsearch>.freeze, [">= 0"])
    s.add_development_dependency(%q<elasticsearch-extensions>.freeze, [">= 0"])
    s.add_development_dependency(%q<elasticsearch-transport>.freeze, [">= 0"])
    s.add_development_dependency(%q<minitest>.freeze, [">= 0"])
    s.add_development_dependency(%q<minitest-reporters>.freeze, [">= 0"])
    s.add_development_dependency(%q<mocha>.freeze, [">= 0"])
    s.add_development_dependency(%q<pry>.freeze, [">= 0"])
    s.add_development_dependency(%q<rake>.freeze, ["~> 13"])
    s.add_development_dependency(%q<shoulda-context>.freeze, [">= 0"])
    s.add_development_dependency(%q<yard>.freeze, [">= 0"])
    s.add_development_dependency(%q<jsonify>.freeze, [">= 0"])
    s.add_development_dependency(%q<hashie>.freeze, [">= 0"])
    s.add_development_dependency(%q<cane>.freeze, [">= 0"])
    s.add_development_dependency(%q<escape_utils>.freeze, [">= 0"])
    s.add_development_dependency(%q<jbuilder>.freeze, [">= 0"])
    s.add_development_dependency(%q<require-prof>.freeze, [">= 0"])
    s.add_development_dependency(%q<simplecov>.freeze, ["~> 0.17", "< 0.18"])
    s.add_development_dependency(%q<simplecov-rcov>.freeze, [">= 0"])
    s.add_development_dependency(%q<test-unit>.freeze, ["~> 2"])
    s.add_development_dependency(%q<ruby-prof>.freeze, [">= 0"])
  else
    s.add_dependency(%q<multi_json>.freeze, [">= 0"])
    s.add_dependency(%q<ansi>.freeze, [">= 0"])
    s.add_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_dependency(%q<elasticsearch>.freeze, [">= 0"])
    s.add_dependency(%q<elasticsearch-extensions>.freeze, [">= 0"])
    s.add_dependency(%q<elasticsearch-transport>.freeze, [">= 0"])
    s.add_dependency(%q<minitest>.freeze, [">= 0"])
    s.add_dependency(%q<minitest-reporters>.freeze, [">= 0"])
    s.add_dependency(%q<mocha>.freeze, [">= 0"])
    s.add_dependency(%q<pry>.freeze, [">= 0"])
    s.add_dependency(%q<rake>.freeze, ["~> 13"])
    s.add_dependency(%q<shoulda-context>.freeze, [">= 0"])
    s.add_dependency(%q<yard>.freeze, [">= 0"])
    s.add_dependency(%q<jsonify>.freeze, [">= 0"])
    s.add_dependency(%q<hashie>.freeze, [">= 0"])
    s.add_dependency(%q<cane>.freeze, [">= 0"])
    s.add_dependency(%q<escape_utils>.freeze, [">= 0"])
    s.add_dependency(%q<jbuilder>.freeze, [">= 0"])
    s.add_dependency(%q<require-prof>.freeze, [">= 0"])
    s.add_dependency(%q<simplecov>.freeze, ["~> 0.17", "< 0.18"])
    s.add_dependency(%q<simplecov-rcov>.freeze, [">= 0"])
    s.add_dependency(%q<test-unit>.freeze, ["~> 2"])
    s.add_dependency(%q<ruby-prof>.freeze, [">= 0"])
  end
end
