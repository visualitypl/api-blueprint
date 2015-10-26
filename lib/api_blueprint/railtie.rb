module ApiBlueprint
  class Railtie < Rails::Railtie
    railtie_name :api_blueprint

    rake_tasks do
      load 'tasks/blueprint.rake'
    end
  end
end
