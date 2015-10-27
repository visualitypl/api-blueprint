module ApiBlueprint
  class Railtie < Rails::Railtie
    railtie_name :api_blueprint

    initializer "api_blueprint.action_controller" do
      ActiveSupport.on_load(:action_controller) do
        include ApiBlueprint::Collect::ControllerHook
      end
    end

    rake_tasks do
      load 'tasks/blueprint.rake'
    end
  end
end
