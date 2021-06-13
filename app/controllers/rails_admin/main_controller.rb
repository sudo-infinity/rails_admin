module RailsAdmin

  class MainController < RailsAdmin::ApplicationController
    before_filter :get_model, :except => [:index]
    before_filter :get_object, :only => [:edit, :update, :delete, :destroy]
    before_filter :get_attributes, :only => [:create, :update]
    before_filter :check_for_cancel, :only => [:create, :update, :destroy, :export, :bulk_destroy]

    def index
      @authorization_adapter.authorize(:index) if @authorization_adapter
      @page_name = t("admin.dashboard.pagename")
      @page_type = "dashboard"

      @history = AbstractHistory.history_latest_summaries
      @month = DateTime.now.month
      @year = DateTime.now.year
      @history= AbstractHistory.history_for_month(@month, @year)

      @abstract_models = RailsAdmin::Config.visible_models.map(&:abstract_model)

      @most_recent_changes = {}
      @count = {}
      @max = 0
      @abstract_models.each do |t|
        current_count = t.count
        @max = current_count > @max ? current_count : @max
        @count[t.pretty_name] = current_count
        @most_recent_changes[t.pretty_name] = AbstractHistory.most_recent_history(t).limit(1).first.try(:updated_at)
      end

      render :layout => 'rails_admin/dashboard'
    end

    def list
      @authorization_adapter.authorize(:list, @abstract_model) if @authorization_adapter
      
      @page_type = @abstract_model.pretty_name.downcase
      @page_name = t("admin.list.select", :name => @model_config.label.downcase)
      
      @objects, @current_page, @page_count, @record_count = list_entries
      @schema ||= { :only => @model_config.list.visible_fields.map {|f| f.name } }
      
      respond_to do |format|
        format.html { render :layout => 'rails_admin/list' }
        format.js { render :layout => 'rails_admin/plain.html.erb' }
        format.json do
          output = if params[:compact]
            @objects.map{ |o| { :id => o.id, :label => o.send(@model_config.object_label_method) } }
          else
            @objects.to_json(@schema)
          end
          if params[:send_data]
            send_data output, :filename => "#{params[:model_name]} #{DateTime.now.strftime("%Y-%m-%d %H:%M:%S")}.json"
          else
            render :json => output
          end
        end
        format.xml do
          output = @objects.to_xml(@schema)
          if params[:send_data]
            send_data output, :filename => "#{params[:model_name]} #{DateTime.now.strftime("%Y-%m-%d %H:%M:%S")}.xml"
          else  
            render :xml => output
          end
        end
        format.csv do
          header, encoding, output = CSVConverter.new(@objects, @schema).to_csv(params[:csv_options])
          if params[:send_data]
            send_data output, 
              :type => "text/csv; charset=#{encoding}; #{"header=present" if header}",
              :disposition => "attachment; filename=#{params[:model_name]} #{DateTime.now.strftime("%Y-%m-%d %H:%M:%S")}.csv"
          else
            render :text => output
          end
        end
      end
    end

    def new
      @object = @abstract_model.new
      if @authorization_adapter
        @authorization_adapter.attributes_for(:new, @abstract_model).each do |name, value|
          @object.send("#{name}=", value)
        end
        @authorization_adapter.authorize(:new, @abstract_model, @object)
      end
      @page_name = t("admin.actions.create").capitalize + " " + @model_config.label.downcase
      @page_type = @abstract_model.pretty_name.downcase
      respond_to do |format|
        format.html { render :layout => 'rails_admin/form' }
        format.js   { render :layout => 'rails_admin/plain.html.erb' }
      end
    end

    def create
      @modified_assoc = []
      @object = @abstract_model.new
      @model_config.create.fields.each {|f| f.parse_input(@attributes) if f.respond_to?(:parse_input) }
      if @authorization_adapter
        @authorization_adapter.attributes_for(:create, @abstract_model).each do |name, value|
          @object.send("#{name}=", value)
        end
        @authorization_adapter.authorize(:create, @abstract_model, @object)
      end
      @object.attributes = @attributes
      @page_name = t("admin.actions.create").capitalize + " " + @model_config.label.downcase
      @page_type = @abstract_model.pretty_name.downcase

      if @object.save
        AbstractHistory.create_history_item("Created #{@model_config.with(:object => @object).object_label}", @object, @abstract_model, _current_user)
        respond_to do |format|
          format.html do
            redirect_to_on_success
          end
          format.js do
            render :json => {
              :id => @object.id,
              :label => @model_config.with(:object => @object).object_label,
            }
          end
        end
      else
        handle_save_error
      end
    end

    def edit
      @authorization_adapter.authorize(:edit, @abstract_model, @object) if @authorization_adapter

      @page_name = t("admin.actions.update").capitalize + " " + @model_config.label.downcase
      @page_type = @abstract_model.pretty_name.downcase

      render :layout => 'rails_admin/form'
    end

    def update
      @authorization_adapter.authorize(:update, @abstract_model, @object) if @authorization_adapter

      @cached_assocations_hash = associations_hash
      @modified_assoc = []

      @page_name = t("admin.actions.update").capitalize + " " + @model_config.label.downcase
      @page_type = @abstract_model.pretty_name.downcase

      @old_object = @object.clone

      @model_config.update.fields.each {|f| f.parse_input(@attributes) if f.respond_to?(:parse_input) }

      @object.attributes = @attributes

      if @object.save
        AbstractHistory.create_update_history @abstract_model, @object, @cached_assocations_hash, associations_hash, @modified_assoc, @old_object, _current_user
        respond_to do |format|
          format.html do
            redirect_to_on_success
          end
          format.js do
            render :json => {
              :id => @object.id,
              :label => @model_config.with(:object => @object).object_label,
            }
          end
        end
      else
        handle_save_error :edit
      end
    end

    def delete
      @authorization_adapter.authorize(:delete, @abstract_model, @object) if @authorization_adapter

      @page_name = t("admin.actions.delete").capitalize + " " + @model_config.label.downcase
      @page_type = @abstract_model.pretty_name.downcase

      render :layout => 'rails_admin/delete'
    end

    def destroy
      @authorization_adapter.authorize(:destroy, @abstract_model, @object) if @authorization_adapter

      @object = @object.destroy
      
      AbstractHistory.create_history_item("Destroyed #{@model_config.with(:object => @object).object_label}", @object, @abstract_model, _current_user)

      redirect_to rails_admin_list_path(:model_name => @abstract_model.to_param), :notice => t("admin.flash.successful", :name => @model_config.label, :action => t("admin.actions.deleted"))
    end
    
    def export
      # todo
      #   limitation: need to display at least one real attribute ('only') so that the full object doesn't get displayed, a way to fix this? maybe force :only => [""]
      #   model_config#with for :methods inside csv content? Perf-optimize it first? Optionnal? Right-now raw data is outputed.
      # maybe
      #   n-levels (backend: possible with xml&json, frontend: not possible, injections check: quite easy)
      @authorization_adapter.authorize(:export, @abstract_model) if @authorization_adapter
      
      if format = params[:json] && :json || params[:csv] && :csv || params[:xml] && :xml
        request.format = format
        @schema = params[:schema].symbolize if params[:schema] # to_json and to_xml expect symbols for keys AND values.
        check_for_injections(@schema)
        list
      else
        @page_name = t("admin.actions.export").capitalize + " " + @model_config.label.downcase
        @page_type = @abstract_model.pretty_name.downcase
        
        render :action => 'export', :layout => 'rails_admin/export'
      end
    end
    
    def bulk_action
      redirect_to rails_admin_list_path, :notice => t("admin.flash.noaction") and return if params[:bulk_ids].blank?
      
      params[:bulk_delete] ? bulk_delete : (params[:bulk_export] ? export : redirect_to(rails_admin_list_path(:model_name => @abstract_model.to_param), :notice => t("admin.flash.noaction")))
    end
    
    def bulk_delete
      @authorization_adapter.authorize(:bulk_delete, @abstract_model) if @authorization_adapter
      @page_name = t("admin.actions.delete").capitalize + " " + @model_config.label.downcase
      @page_type = @abstract_model.pretty_name.downcase
      
      @bulk_objects, @current_page, @page_count, @record_count = list_entries
      
      render :action => 'bulk_delete', :layout => 'rails_admin/delete'
    end

    def bulk_destroy
      @authorization_adapter.authorize(:bulk_destroy, @abstract_model) if @authorization_adapter
      
      scope = @authorization_adapter && @authorization_adapter.query(params[:action].to_sym, @abstract_model)
      @destroyed_objects = @abstract_model.destroy(params[:bulk_ids], scope)
      
      @destroyed_objects.each do |object|
        message = "Destroyed #{@model_config.with(:object => object).object_label}"
        AbstractHistory.create_history_item(message, object, @abstract_model, _current_user)
      end

      redirect_to rails_admin_list_path, :notice => t("admin.flash.successful", :name => @model_config.label, :action => t("admin.actions.deleted"))
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

    def get_bulk_objects(ids)
      scope = @authorization_adapter && @authorization_adapter.query(params[:action].to_sym, @abstract_model)
      objects = @abstract_model.get_bulk(ids, scope)

      not_found unless objects
      objects
    end

    def get_sort_hash
      sort = params[:sort] || RailsAdmin.config(@abstract_model).list.sort_by
      field = @model_config.list.fields.find{ |f| f.name.to_s == sort.to_s }
      
      column = if field.nil? || field && [true, false].include?(field.sortable)
        sort
      elsif field.association?
        "#{field.associated_model_config.abstract_model.model.table_name}.#{field.sortable}"
      else
        field.sortable
      end
      {:sort => column}
    end

    def get_sort_reverse_hash
      sort_reverse = if params[:sort]
          params[:sort_reverse] == 'true'
      else
        not RailsAdmin.config(@abstract_model).list.sort_reverse?
      end
      {:sort_reverse => sort_reverse}
    end

    def get_conditions_hash(query, filters)
      
      # TODO for filtering engine
      #   some severe styling, it's fugly
      #   some severe javascript refactoring, it's fugly too
      #   DOC: finish searchable
      #   error messages for the tricky cases where:
      #     query can't be made on any of the avalaible attributes (will it happen a lot?)
      #     filter can't apply to the targetted attribute
      
      #   extend engine to :
      #      :boolean with checkboxes
      #      :belongs_to_association with dropdown/autocomplete
      #      :enum with dropdown
      #      :string, :text with starts_with/ends_with/exact options
      
      #  LATER
      #   find a way for complex request (OR/AND)?
      #   find a way to force a column? Handy for 
      
      
      return {} if query.blank? && filters.blank? # perf
      
      @like_operator =  "ILIKE" if ActiveRecord::Base.configurations[Rails.env]['adapter'] == "postgresql"
      @like_operator ||= "LIKE"
      @searchable_fields = @model_config.list.fields.inject({}){ |memo, field| memo[field.name] = field.searchable_columns; memo }

      query_statements = []
      filters_statements = []
      values = []
      conditions = [""]

      
      if query.present?
        @searchable_fields.map{|k,v|v}.flatten.each do |field_infos|
          statement, value = build_statement(field_infos[:column], field_infos[:type], query, 'default')
          if statement && value
            query_statements << statement
            values << value
          end
        end
      end
      
      unless query_statements.empty?
        conditions[0] += " AND " unless conditions == [""]
        conditions[0] += "(#{query_statements.join(" OR ")})"  # any column field will do
      end
      
      if filters.present?
        filters.each_pair do |field_name, values_dump|
          values_dump.each do |value_dump|
            field_statements = []
            @searchable_fields[field_name.intern].each do |field_infos|
              statement, value = build_statement(field_infos[:column], field_infos[:type], value_dump[:value], (value_dump[:operator] || 'default'))
              if statement && value
                field_statements << statement
                values << value
              end
            end
            filters_statements << "(#{field_statements.join(' OR ')})" unless field_statements.empty?
          end
        end
      end
      
      unless filters_statements.empty?
       conditions[0] += " AND " unless conditions == [""]
       conditions[0] += "#{filters_statements.join(" AND ")}" # filters should all be true
      end
      
      conditions += values
      conditions != [""] ? { :conditions => conditions } : {}
    end
    
    def build_statement(column, type, value, operator)
      case type
      when :boolean
         ["(#{column} #{operator == 'default' ? '=' : operator} ?)", ['true', 't', '1'].include?(value)] if ['true', 'false', 't', 'f', '1', '0'].include?(value)
      when :integer, :belongs_to_association
         ["(#{column} #{operator == 'default' ? '=' : operator} ?)", value.to_i] if value.to_i.to_s == value
      when :string, :text
        ["(#{column} #{@like_operator} ?)", "%#{value}%"]
      when :enum
        ["(#{column} #{@like_operator} ?)", value]
      end
    end

    def get_attributes
      @attributes = params[@abstract_model.to_param.singularize.gsub('~','_')] || {}
      @attributes.each do |key, value|
        # Deserialize the attribute if attribute is serialized
        if @abstract_model.model.serialized_attributes.keys.include?(key) and value.is_a? String
          @attributes[key] = YAML::load(value)
        end
        # Delete fields that are blank
        @attributes[key] = nil if value.blank?
      end
    end

    def redirect_to_on_success
      notice = t("admin.flash.successful", :name => @model_config.label, :action => t("admin.actions.#{params[:action]}d"))
      if params[:_add_another]
        redirect_to rails_admin_new_path, :notice => notice
      elsif params[:_add_edit]
        redirect_to rails_admin_edit_path(:id => @object.id), :notice => notice
      else
        redirect_to rails_admin_list_path, :notice => notice
      end
    end

    def handle_save_error whereto = :new
      action = params[:action]

      flash.now[:error] = t("admin.flash.error", :name => @model_config.label, :action => t("admin.actions.#{action}d"))
      flash.now[:error] += ". #{@object.errors[:base].to_sentence}" unless @object.errors[:base].blank?
      
      respond_to do |format|
        format.html { render whereto, :layout => 'rails_admin/form', :status => :not_acceptable }
        format.js   { render whereto, :layout => 'rails_admin/plain.html.erb', :status => :not_acceptable  }
      end
    end

    def check_for_cancel
      redirect_to rails_admin_list_path, :notice => t("admin.flash.noaction") if params[:_continue]
    end

    def list_entries(other = {})
      return [get_bulk_objects(params[:bulk_ids]), 1, 1, "unknown"] if params[:bulk_ids].present?
      
      associations = @model_config.list.fields.select {|f| f.association? && !f.polymorphic? }.map {|f| f.association[:name] }
      options = get_sort_hash.merge(get_sort_reverse_hash).merge(get_conditions_hash(params[:query], params[:filters])).merge(other).merge(associations.empty? ? {} : { :include => associations })

      scope = @authorization_adapter && @authorization_adapter.query(:list, @abstract_model)
      current_page = (params[:page] || 1).to_i
      
      if params[:all]
        objects = @abstract_model.all(options, scope)
        page_count = 1
        record_count = objects.count
      else
        options.merge!(:page => current_page, :per_page => @model_config.list.items_per_page)
        
        page_count, objects = @abstract_model.paginated(options, scope)
        options.delete(:page)
        options.delete(:per_page)
        options.delete(:offset)
        options.delete(:limit)
        record_count = @abstract_model.count(options, scope)
      end

      [objects, current_page, page_count, record_count]
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
    
    def check_for_injections(schema)
      check_injections_for(@model_config, (schema[:only] || []) + (schema[:methods] || []))
      allowed_associations = @model_config.export.visible_fields.select{ |f| f.association? && !f.association[:options][:polymorphic] }.map(&:association)
      (schema[:include] || []).each do |association_name, schema|
        association = allowed_associations.find { |aa| aa[:name] == association_name }
        raise("Security Exception: #{association[:name]} association not available for #{@model_config.abstract_model.pretty_name}") unless association
        associated_model = association[:type] == :belongs_to ? association[:parent_model] : association[:child_model]
        check_injections_for(RailsAdmin.config(AbstractModel.new(associated_model)), (schema[:only] || []) + (schema[:methods] || []))
      end
    end
    
    def check_injections_for(model_config, methods_name)
      available_fields = model_config.export.visible_fields.select{ |f| !f.association? || f.association[:options][:polymorphic] }.map do |field|
        if field.association? && field.association[:options][:polymorphic]
          [field.name, model_config.abstract_model.properties.find {|p| field.association[:options][:foreign_type] == p[:name].to_s }[:name]]
        else
          field.name
        end
      end.flatten
      unallowed_fields = (methods_name - available_fields)
      raise("Security Exception: #{unallowed_fields.inspect} methods not available for #{@model_config.abstract_model.pretty_name}") unless unallowed_fields.empty?
    end
  end
end
