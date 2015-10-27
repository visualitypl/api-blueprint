module ApiBlueprint
  Collect = Module.new
  Compile = Module.new
end

require 'redcarpet'
require 'api_blueprint/collect/controller_hook'
require 'api_blueprint/collect/merge'
require 'api_blueprint/collect/preprocessor'
require 'api_blueprint/collect/renderer'
require 'api_blueprint/collect/spec_hook'
require 'api_blueprint/collect/storage'
require 'api_blueprint/compile/compile'
require 'api_blueprint/compile/storage'
require 'api_blueprint/railtie'
require 'api_blueprint/version'
