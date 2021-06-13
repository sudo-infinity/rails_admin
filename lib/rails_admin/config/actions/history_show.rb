module RailsAdmin
  module Config
    module Actions
      class HistoryShow < RailsAdmin::Config::Actions::Base
        RailsAdmin::Config::Actions.register(self)
        
        register_instance_option :object_level do
          true
        end
        
        register_instance_option :route_fragment do
          'history'
        end
        
        register_instance_option :controller do
          Proc.new do
            @general = false
            @history = @auditing_adapter && @auditing_adapter.listing_for_object(@abstract_model, @object, params[:query], params[:sort], params[:sort_reverse], params[:all], params[:page]) || []

            render @action.template_name, :layout => request.xhr? ? false : 'rails_admin/application'
          end
        end
        
        register_instance_option :template_name do
          :history
        end
      end
    end
  end
end
