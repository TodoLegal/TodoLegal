# -*- encoding: utf-8 -*-
# stub: simple_token_authentication 1.17.0 ruby lib

Gem::Specification.new do |s|
  s.name = "simple_token_authentication".freeze
  s.version = "1.17.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Gonzalo Bulnes Guilpain".freeze]
  s.date = "2019-09-21"
  s.email = ["gon.bulnes@gmail.com".freeze]
  s.homepage = "https://github.com/gonzalo-bulnes/simple_token_authentication".freeze
  s.licenses = ["GPL-3.0+".freeze]
  s.rubygems_version = "3.2.15".freeze
  s.summary = "Simple (but safe) token authentication for Rails apps or API with Devise.".freeze

  s.installed_by_version = "3.2.15" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<actionmailer>.freeze, [">= 3.2.6", "< 7"])
    s.add_runtime_dependency(%q<actionpack>.freeze, [">= 3.2.6", "< 7"])
    s.add_runtime_dependency(%q<devise>.freeze, [">= 3.2", "< 6"])
    s.add_development_dependency(%q<rspec>.freeze, ["~> 3.0"])
    s.add_development_dependency(%q<inch>.freeze, ["~> 0.4"])
    s.add_development_dependency(%q<activerecord>.freeze, [">= 3.2.6", "< 7"])
    s.add_development_dependency(%q<mongoid>.freeze, [">= 3.1.0", "< 8"])
    s.add_development_dependency(%q<appraisal>.freeze, ["~> 2.0"])
  else
    s.add_dependency(%q<actionmailer>.freeze, [">= 3.2.6", "< 7"])
    s.add_dependency(%q<actionpack>.freeze, [">= 3.2.6", "< 7"])
    s.add_dependency(%q<devise>.freeze, [">= 3.2", "< 6"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.0"])
    s.add_dependency(%q<inch>.freeze, ["~> 0.4"])
    s.add_dependency(%q<activerecord>.freeze, [">= 3.2.6", "< 7"])
    s.add_dependency(%q<mongoid>.freeze, [">= 3.1.0", "< 8"])
    s.add_dependency(%q<appraisal>.freeze, ["~> 2.0"])
  end
end
