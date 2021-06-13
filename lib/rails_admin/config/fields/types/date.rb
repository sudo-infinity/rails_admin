require 'rails_admin/config/fields/types/datetime'

module RailsAdmin
  module Config
    module Fields
      module Types
        class Date < RailsAdmin::Config::Fields::Types::Datetime
          # Register field type for the type loader
          RailsAdmin::Config::Fields::Types::register(self)

          @column_width = 90
          @datepicker_options = {}
          @format = :long
          @i18n_scope = [:date, :formats]
        end
      end
    end
  end
end