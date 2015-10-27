lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'api_blueprint/version'

Gem::Specification.new do |spec|
  spec.name     = 'api_blueprint'
  spec.version  = ApiBlueprint::VERSION
  spec.authors  = ['Karol Słuszniak']
  spec.email    = 'k.sluszniak@visuality.pl'
  spec.homepage = 'http://github.com/visualitypl/api-blueprint'
  spec.license  = 'MIT'
  spec.platform = Gem::Platform::RUBY

  spec.summary = "Semi-automatic solution for creating Rails app's API documentation based on RSpec request specs."
  spec.description = spec.summary

  spec.files            = Dir["lib/**/*"]
  spec.has_rdoc         = false
  spec.extra_rdoc_files = ["README.md"]
  spec.require_paths    = ["lib"]

  spec.add_runtime_dependency 'filewatcher'
  spec.add_runtime_dependency 'nokogiri'
  spec.add_runtime_dependency 'rails'
  spec.add_runtime_dependency 'redcarpet'
  spec.add_runtime_dependency 'rspec-rails'
end