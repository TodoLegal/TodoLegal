# -*- encoding: utf-8 -*-
# stub: capistrano3-nginx 2.1.6 ruby lib

Gem::Specification.new do |s|
  s.name = "capistrano3-nginx".freeze
  s.version = "2.1.6"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Juan Ignacio Donoso".freeze]
  s.date = "2017-03-24"
  s.description = "Adds suuport to nginx for Capistrano 3.x".freeze
  s.email = ["jidonoso@gmail.com".freeze]
  s.homepage = "https://github.com/platanus/capistrano3-nginx".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.2.3".freeze
  s.summary = "Adds suuport to nginx for Capistrano 3.x".freeze

  s.installed_by_version = "3.2.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<capistrano>.freeze, [">= 3.0.0"])
    s.add_development_dependency(%q<rake>.freeze, [">= 0"])
  else
    s.add_dependency(%q<capistrano>.freeze, [">= 3.0.0"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
  end
end
