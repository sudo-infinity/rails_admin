require 'rails_admin/abstract_history'

module RailsAdmin
  class MainController < RailsAdmin::ApplicationController
    before_filter :get_model, :except => [:index]
    before_filter :get_object, :only => [:edit, :update, :delete, :destroy]
    before_filter :get_bulk_objects, :only => [:bulk_delete, :bulk_destroy]
    before_filter :get_attributes, :only => [:create, :update]
    before_filter :check_for_cancel, :only => [:create, :update, :destroy, :bulk_destroy]

    def index
      @page_name = t("admin.dashboard.pagename")
      @page_type = "dashboard"

      @history = History.latest
      # history listing with ref = 0 and section = 4
      @historyListing, @current_month = History.get_history_for_month(0, 4)

      @abstract_models = RailsAdmin::AbstractModel.all

      @count = {}
      @max = 0
      @abstract_models.each do |t|
        current_count = t.count
        @max = current_count > @max ? current_count : @max
        @count[t.pretty_name] = current_count
      end

      render :layout => 'rails_admin/dashboard'
    end

    def list
      list_entries
      @xhr = request.xhr?
      visible = lambda { @model_config.list.visible_fields.map {|f| f.name } }
      respond_to do |format|
        format.html { render :layout => @xhr ? false : 'rails_admin/list' }
        format.json { render :json => @objects.to_json(:only => visible.call) }
        format.xml { render :xml => @objects.to_json(:only => visible.call) }
      end
    end

    def new
      @object = @abstract_model.new
      @page_name = t("admin.actions.create").capitalize + " " + @model_config.create.label.downcase
      @page_type = @abstract_model.pretty_name.downcase
      render :layout => 'rails_admin/form'
    end

    def create
      @modified_assoc = []
      @object = @abstract_model.new
      @object.send :attributes=, @attributes, false
      @page_name = t("admin.actions.create").capitalize + " " + @model_config.create.label.downcase
      @page_type = @abstract_model.pretty_name.downcase

      if @object.save && update_all_associations
        RailsAdmin.create_history_item("Created #{@model_config.bind(:object, @object).list.object_label}", @object, @abstract_model, _current_user)
        redirect_to_on_success
      else
        render_error
      end
    end

    def edit
      @page_name = t("admin.actions.update").capitalize + " " + @model_config.update.label.downcase
      @page_type = @abstract_model.pretty_name.downcase
      render :layout => 'rails_admin/form'
    end

    def update
      @cached_assocations_hash = associations_hash
      @modified_assoc = []

      @page_name = t("admin.actions.update").capitalize + " " + @model_config.update.label.downcase
      @page_type = @abstract_model.pretty_name.downcase

      @old_object = @object.clone

      @object.send :attributes=, @attributes, false
      if @object.save && update_all_associations
        RailsAdmin.create_update_history @abstract_model, @object, @cached_assocations_hash, associations_hash, @modified_assoc, @old_object, _current_user
        redirect_to_on_success
      else
        render_error :edit
      end
    end

    def delete
      @page_name = t("admin.actions.delete").capitalize + " " + @model_config.list.label.downcase
      @page_type = @abstract_model.pretty_name.downcase

      render :layout => 'rails_admin/delete'
    end

    def destroy
      @object = @object.destroy
      flash[:notice] = t("admin.delete.flash_confirmation", :name => @model_config.list.label)

      RailsAdmin.create_history_item("Destroyed #{@model_config.bind(:object, @object).list.object_label}", @object, @abstract_model, _current_user)

      redirect_to rails_admin_list_path(:model_name => @abstract_model.to_param)
    end

    def bulk_delete
      @page_name = t("admin.actions.delete").capitalize + " " + @model_config.list.label.downcase
      @page_type = @abstract_model.pretty_name.downcase

      render :layout => 'rails_admin/delete'
    end
    
    def bulk_destroy
      @destroyed_objects = @abstract_model.destroy(params[:bulk_ids])

      @destroyed_objects.each do |object|
        message = "Destroyed #{@model_config.bind(:object, object).list.object_label}"
        RailsAdmin.create_history_item(message, object, @abstract_model, _current_user)
      end

      redirect_to rails_admin_list_path(:model_name => @abstract_model.to_param)
    end

    def show_history
      @page_type = @abstract_model.pretty_name.downcase
      @page_name = t("admin.history.page_name", :name => @model_config.list.label)
      @general = true

      options = {}
      options[:order] = "created_at DESC"
      options[:conditions] = []
      options[:conditions] << conditions = "#{History.connection.quote_column_name(:table)} = ?"
      options[:conditions] << @abstract_model.pretty_name

      if params[:id]
        get_object
        @page_name = t("admin.history.page_name", :name => @model_config.bind(:object, @object).list.object_label)
        options[:conditions][0] += " and #{History.connection.quote_column_name(:item)} = ?"
        options[:conditions] << params[:id]
        @general = false
      end

      if params[:query]
        options[:conditions][0] += " and (#{History.connection.quote_column_name(:message)} LIKE ? or #{History.connection.quote_column_name(:username)} LIKE ?)"
        options[:conditions] << "%#{params["query"]}%"
        options[:conditions] << "%#{params["query"]}%"
      end

      if params["sort"]
        options.delete(:order)
        if params["sort_reverse"] == "true"
          options[:order] = "#{params["sort"]} desc"
        else
          options[:order] = params["sort"]
        end
      end

      @history = History.find(:all, options)

      if @general and not params[:all]
        @current_page = (params[:page] || 1).to_i
        options.merge!(:page => @current_page, :per_page => 20)
        @page_count, @history = History.paginated(options)
      end

      render :layout => request.xhr? ? false : 'rails_admin/list'
    end

    def handle_error(e)
      if RailsAdmin::AuthenticationNotConfigured === e
        Rails.logger.error e.message
        Rails.logger.error e.backtrace.join("\n")

        @error = e
        render 'authentication_not_setup', :status => 401
      else
        super
      end
    end

    private

    def get_model
      model_name = to_model_name(params[:model_name])
      @abstract_model = RailsAdmin::AbstractModel.new(model_name)
      @model_config = RailsAdmin.config(@abstract_model)
      not_found if @model_config.excluded?
      @properties = @abstract_model.properties
    end

    def get_object
      @object = @abstract_model.get(params[:id])
      @model_config.bind(:object, @object)
      not_found unless @object
    end
    
    def get_bulk_objects
      @bulk_ids = params[:bulk_ids]
      @bulk_objects = @abstract_model.get_bulk(@bulk_ids)
      not_found unless @bulk_objects
    end

    def get_sort_hash
      sort = params[:sort]
      sort ? {:sort => sort} : {}
    end

    def get_sort_reverse_hash
      sort_reverse = params[:sort_reverse]
      sort_reverse ? {:sort_reverse => sort_reverse == "true"} : {}
    end

    def get_query_hash(options)
      query = params[:query]
      return {} unless query
      statements = []
      values = []
      conditions = options[:conditions] || [""]
      table_name = @abstract_model.model.table_name

      @properties.select{|property| property[:type] == :string}.each do |property|
        statements << "(#{table_name}.#{property[:name]} LIKE ?)"
        values << "%#{query}%"
      end

      conditions[0] += " AND " unless conditions == [""]
      conditions[0] += statements.join(" OR ")
      conditions += values
      conditions != [""] ? {:conditions => conditions} : {}
    end

    def get_filter_hash(options)
      filter = params[:filter]
      return {} unless filter
      statements = []
      values = []
      conditions = options[:conditions] || [""]
      table_name = @abstract_model.model.table_name

      filter.each_pair do |key, value|
        @properties.select{|property| property[:type] == :boolean && property[:name] == key.to_sym}.each do |property|
          statements << "(#{table_name}.#{key} = ?)"
          values << (value == "true")
        end
      end

      conditions[0] += " AND " unless conditions == [""]
      conditions[0] += statements.join(" AND ")
      conditions += values
      conditions != [""] ? {:conditions => conditions} : {}
    end

    def get_attributes
      @attributes = params[@abstract_model.to_param] || {}
      @attributes.each do |key, value|
        # Deserialize the attribute if attribute is serialized
        if @abstract_model.model.serialized_attributes.keys.include?(key)
          @attributes[key] = YAML::load(value)
        end
        # Delete fields that are blank
        @attributes[key] = nil if value.blank?
      end
    end

    def update_all_associations
      @abstract_model.associations.each do |association|
        if params[:associations] && params[:associations].has_key?(association[:name])
          ids = (params[:associations] || {}).delete(association[:name])
          case association[:type]
          when :has_one
            update_association(association, ids)
          when :has_many, :has_and_belongs_to_many
            update_associations(association, ids.to_a)
          end
        end
      end
    end

    def update_association(association, id = nil)
      associated_model = RailsAdmin::AbstractModel.new(association[:child_model])
      if object = associated_model.get(id)
        if object.send(association[:child_key].first) != @object.id
          @modified_assoc << association[:pretty_name]
        end
        object.update_attributes(association[:child_key].first => @object.id)
      end
    end

    def update_associations(association, ids = [])
      associated_model = RailsAdmin::AbstractModel.new(association[:child_model])
      @object.send "#{association[:name]}=", ids.collect{|id| associated_model.get(id)}.compact
      @object.save
    end

    def redirect_to_on_success
      param = @abstract_model.to_param
      pretty_name = @model_config.update.label
      action = params[:action]

      if params[:_add_another]
        flash[:notice] = t("admin.flash.successful", :name => pretty_name, :action => t("admin.actions.#{action}d"))
        redirect_to rails_admin_new_path(:model_name => param)
      elsif params[:_add_edit]
        flash[:notice] = t("admin.flash.successful", :name => pretty_name, :action => t("admin.actions.#{action}d"))
        redirect_to rails_admin_edit_path(:model_name => param, :id => @object.id)
      else
        flash[:notice] = t("admin.flash.successful", :name => pretty_name, :action => t("admin.actions.#{action}d"))
        redirect_to rails_admin_list_path(:model_name => param)
      end
    end

    def render_error whereto = :new
      action = params[:action]
      flash.now[:error] = t("admin.flash.error", :name => @model_config.update.label, :action => t("admin.actions.#{action}d"))
      render whereto, :layout => 'rails_admin/form'
    end

    def to_model_name(param)
      param.split("::").map{|x| x.singularize.camelize}.join("::")
    end

    def check_for_cancel
      if params[:_continue]
        flash[:notice] = t("admin.flash.noaction")
        redirect_to rails_admin_list_path(:model_name => @abstract_model.to_param)
      end
    end

    def list_entries(other = {})
      options = {}
      options.merge!(get_sort_hash)
      options.merge!(get_sort_reverse_hash)
      options.merge!(get_query_hash(options))
      options.merge!(get_filter_hash(options))
      per_page = @model_config.list.items_per_page

      # external filter
      options.merge!(other)

      associations = @model_config.list.visible_fields.select {|f| f.association? }.map {|f| f.association[:name] }
      options.merge!(:include => associations) unless associations.empty?

      if params[:all]
        options.merge!(:limit => per_page * 2)
        @objects = @abstract_model.all(options).reverse
      else
        @current_page = (params[:page] || 1).to_i
        options.merge!(:page => @current_page, :per_page => per_page)
        @page_count, @objects = @abstract_model.paginated(options)
        options.delete(:page)
        options.delete(:per_page)
        options.delete(:offset)
        options.delete(:limit)
      end

      @record_count = @abstract_model.count(options)

      @page_type = @abstract_model.pretty_name.downcase
      @page_name = t("admin.list.select", :name => @model_config.list.label.downcase)
    end

    def associations_hash
      associations = {}
      @abstract_model.associations.each do |association|
        if [:has_many, :has_and_belongs_to_many].include?(association[:type])
          records = Array(@object.send(association[:name]))
          associations[association[:name]] = records.collect(&:id)
        end
      end
      associations
    end

  end
end
