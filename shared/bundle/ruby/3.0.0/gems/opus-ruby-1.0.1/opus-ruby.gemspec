# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'opus-ruby/version'

Gem::Specification.new do |spec|
  spec.name          = "opus-ruby"
  spec.version       = Opus::VERSION
  spec.authors       = ["Matthew Perry"]
  spec.email         = ["muffinman616@gmail.com"]
  spec.description   = %q{Ruby FFI Gem for the OPUS Audio Codec}
  spec.summary       = %q{Ruby FFI wrapper for the OPUS Audio Codec C library for audio encoding}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"

  spec.add_dependency "ffi"
end
