require 'rails_admin/config/fields/association'

module RailsAdmin
  module Config
    module Fields
      module Types
        class BelongsToAssociation < RailsAdmin::Config::Fields::Association
          RailsAdmin::Config::Fields::Types::register(self)

          register_instance_option :formatted_value do
            (o = value) && o.send(associated_model_config.object_label_method)
          end

          register_instance_option :sortable do
            @sortable ||= associated_model_config.abstract_model.properties.map{ |p| p[:name] }.include?(associated_model_config.object_label_method) ? associated_model_config.object_label_method : {self.abstract_model.model.table_name => self.method_name}
          end

          register_instance_option :searchable do
            @searchable ||= associated_model_config.abstract_model.properties.map{ |p| p[:name] }.include?(associated_model_config.object_label_method) ? [associated_model_config.object_label_method, {self.abstract_model.model => self.method_name}] : {self.abstract_model.model => self.method_name}
          end

          register_instance_option :partial do
            nested_form ? :form_nested_one : :form_filtering_select
          end

          def selected_id
            bindings[:object].send(foreign_key)
          end

          def method_name
            nested_form ? "#{self.name}_attributes" : association[:foreign_key]
          end
          
          def multiple?
            false
          end
        end
      end
    end
  end
end
