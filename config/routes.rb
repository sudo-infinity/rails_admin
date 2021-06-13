RailsAdmin::Engine.routes.draw do
  controller "main" do
    RailsAdmin::Config::Actions.root.each { |action| match "/#{action.route_fragment}", :to => action.action_name, :as => action.action_name, :via => action.http_methods }
    scope ":model_name" do
      RailsAdmin::Config::Actions.model.each { |action| match "/#{action.route_fragment}", :to => action.action_name, :as => action.action_name, :via => action.http_methods }
      post  "/bulk_action",  :to => :bulk_action,   :as => "bulk_action"
      scope ":id" do
        RailsAdmin::Config::Actions.object.each { |action| match "/#{action.route_fragment}", :to => action.action_name, :as => action.action_name, :via => action.http_methods }
      end
    end
  end
end
