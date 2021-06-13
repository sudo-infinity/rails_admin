require 'rails_admin/config/fields/base'
require 'rails_admin/config/fields/types/file_upload'

module RailsAdmin
  module Config
    module Fields
      module Types
        # Field type that supports Paperclip file uploads
        class PaperclipFile < RailsAdmin::Config::Fields::Types::FileUpload
          RailsAdmin::Config::Fields::Types.register(self)

          register_instance_option(:partial) do
            if parent.kind_of?(RailsAdmin::Config::Sections::Update)
              :form_paperclip_file
            else
              :show_paperclip_file
            end
          end

          register_instance_option(:delete_method) do
            "delete_#{name}" if bindings[:object].respond_to?("delete_#{name}")
          end

          register_instance_option(:thumb_method) do
            nil
          end

          def value
            if bindings[:object].send(name).file?
              bindings[:object].send(name).url
            else
              nil
            end
          end
        end
      end
    end
  end
end
