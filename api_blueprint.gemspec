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

  spec.description = "You start with method list generated from RSpec request specs. For each method, you get a list of parameters and examples. Then, you can extend it in whatever way you need using Markdown syntax. You can organize documentation files into partials. Upon any API change, like serializer change that changes responses, you can update automatically generated parts of docs. Once done, you can compile your documentation into single, nicely styled HTML file. You can also auto-deploy it via SSH."

  spec.files            = Dir["lib/**/*.rb", "lib/**/*.rake"]
  spec.has_rdoc         = false
  spec.extra_rdoc_files = ["README.md"]
  spec.require_paths    = ["lib"]

  spec.add_runtime_dependency 'filewatcher'
  spec.add_runtime_dependency 'nokogiri'
  spec.add_runtime_dependency 'rails'
  spec.add_runtime_dependency 'redcarpet'
  spec.add_runtime_dependency 'rspec-rails'
end