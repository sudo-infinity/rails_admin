require 'spec_helper'

describe "RailsAdmin Config DSL Edit Section" do
  
  subject { page }
  
  describe "field groupings" do

    it "should be hideable" do
      RailsAdmin.config Team do
        edit do
          group :default do
            label "Hidden group"
            hide
          end
        end
      end
      visit rails_admin_new_path(:model_name => "team")
      # Should not have the group header
      should_not have_selector("legend", :text => "Hidden Group")
      # Should not have any of the group's fields either
      should_not have_selector("select#team_division_id")
      should_not have_selector("input#team_name")
      should_not have_selector("input#team_logo_url")
      should_not have_selector("input#team_manager")
      should_not have_selector("input#team_ballpark")
      should_not have_selector("input#team_mascot")
      should_not have_selector("input#team_founded")
      should_not have_selector("input#team_wins")
      should_not have_selector("input#team_losses")
      should_not have_selector("input#team_win_percentage")
      should_not have_selector("input#team_revenue")
    end

    it "should hide association groupings by the name of the association" do
      RailsAdmin.config Team do
        edit do
          group :players do
            hide
          end
        end
      end
      visit rails_admin_new_path(:model_name => "team")
      # Should not have the group header
      should_not have_selector("legend", :text => "Players")
      # Should not have any of the group's fields either
      should_not have_selector("select#team_player_ids")
    end

    it "should be renameable" do
      RailsAdmin.config Team do
        edit do
          group :default do
            label "Renamed group"
          end
        end
      end
      visit rails_admin_new_path(:model_name => "team")

      should have_selector("legend", :text => "Renamed group")
    end

    it "should have accessor for its fields" do
      RailsAdmin.config Team do
        edit do
          group :default do
            field :name
            field :logo_url
          end
          group :belongs_to_associations do
            label "Belong's to associations"
            field :division_id
          end
        end
      end
      visit rails_admin_new_path(:model_name => "team")
      should have_selector("legend", :text => "Basic info")
      should have_selector("legend", :text => "Belong's to associations")
      should have_selector(".field") do |elements|
        elements[0].should have_selector("#team_name")
        elements[1].should have_selector("#team_logo_url")
        elements[2].should have_selector("#team_division_id")
        elements.length.should == 3
      end
    end

    it "should have accessor for its fields by type" do
      RailsAdmin.config Team do
        edit do
          group :default do
            field :name
            field :logo_url
          end
          group :other do
            field :division_id
            field :manager
            field :ballpark
            fields_of_type :string do
              label { "#{label} (STRING)" }
            end
          end
        end
      end
      visit rails_admin_new_path(:model_name => "team")
      should have_selector(".field") do |elements|
        elements.should have_selector("label", :text => "Name")
        elements.should have_selector("label", :text => "Logo url")
        elements.should have_selector("label", :text => "Division")
        elements.should have_selector("label", :text => "Manager (STRING)")
        elements.should have_selector("label", :text => "Ballpark (STRING)")
      end
    end
  end

  describe "items' fields" do

    it "should show all by default" do
      visit rails_admin_new_path(:model_name => "team")
      should have_selector("select#team_division_id")
      should have_selector("input#team_name")
      should have_selector("input#team_logo_url")
      should have_selector("input#team_manager")
      should have_selector("input#team_ballpark")
      should have_selector("input#team_mascot")
      should have_selector("input#team_founded")
      should have_selector("input#team_wins")
      should have_selector("input#team_losses")
      should have_selector("input#team_win_percentage")
      should have_selector("input#team_revenue")
      should have_selector("select#team_player_ids")
      should have_selector("select#team_fan_ids")
    end

    it "should appear in order defined" do
      RailsAdmin.config Team do
        edit do
          field :manager
          field :division_id
          field :name
        end
      end
      visit rails_admin_new_path(:model_name => "team")
      should have_selector(".field") do |elements|
        elements[0].should have_selector("#team_manager")
        elements[1].should have_selector("#team_division_id")
        elements[2].should have_selector("#team_name")
      end
    end

    it "should only show the defined fields if some fields are defined" do
      RailsAdmin.config Team do
        edit do
          field :division_id
          field :name
        end
      end
      visit rails_admin_new_path(:model_name => "team")
      should have_selector(".field") do |elements|
        elements[0].should have_selector("#team_division_id")
        elements[1].should have_selector("#team_name")
        elements.length.should == 2
      end
    end

    it "should delegates the label option to the ActiveModel API" do
      RailsAdmin.config Team do
        edit do
          field :manager
          field :fans
        end
      end

      visit rails_admin_new_path(:model_name => "team")
      should have_selector(".field") do |elements|
        elements[0].should have_selector("label", :text => "Team Manager")
        elements[1].should have_selector("label", :text => "Some Fans")
      end
    end

    it "should be renameable" do
      RailsAdmin.config Team do
        edit do
          field :manager do
            label "Renamed field"
          end
          field :division_id
          field :name
        end
      end
      visit rails_admin_new_path(:model_name => "team")
      should have_selector(".field") do |elements|
        elements[0].should have_selector("label", :text => "Renamed field")
        elements[1].should have_selector("label", :text => "Division")
        elements[2].should have_selector("label", :text => "Name")
      end
    end

    it "should be renameable by type" do
      RailsAdmin.config Team do
        edit do
          fields_of_type :string do
            label { "#{label} (STRING)" }
          end
        end
      end
      visit rails_admin_new_path(:model_name => "team")
      should have_selector(".field") do |elements|
        elements.should have_selector("label", :text => "Division")
        elements.should have_selector("label", :text => "Name (STRING)")
        elements.should have_selector("label", :text => "Logo url (STRING)")
        elements.should have_selector("label", :text => "Manager (STRING)")
        elements.should have_selector("label", :text => "Ballpark (STRING)")
        elements.should have_selector("label", :text => "Mascot (STRING)")
        elements.should have_selector("label", :text => "Founded")
        elements.should have_selector("label", :text => "Wins")
        elements.should have_selector("label", :text => "Losses")
        elements.should have_selector("label", :text => "Win percentage")
        elements.should have_selector("label", :text => "Revenue")
        elements.should have_selector("label", :text => "Players")
        elements.should have_selector("label", :text => "Fans")
      end
    end

    it "should be globally renameable by type" do
      RailsAdmin::Config.models do
        edit do
          fields_of_type :string do
            label { "#{label} (STRING)" }
          end
        end
      end
      visit rails_admin_new_path(:model_name => "team")
      should have_selector(".field") do |elements|
        elements.should have_selector("label", :text => "Division")
        elements.should have_selector("label", :text => "Name (STRING)")
        elements.should have_selector("label", :text => "Logo url (STRING)")
        elements.should have_selector("label", :text => "Manager (STRING)")
        elements.should have_selector("label", :text => "Ballpark (STRING)")
        elements.should have_selector("label", :text => "Mascot (STRING)")
        elements.should have_selector("label", :text => "Founded")
        elements.should have_selector("label", :text => "Wins")
        elements.should have_selector("label", :text => "Losses")
        elements.should have_selector("label", :text => "Win percentage")
        elements.should have_selector("label", :text => "Revenue")
        elements.should have_selector("label", :text => "Players")
        elements.should have_selector("label", :text => "Fans")
      end
    end

    it "should be hideable" do
      RailsAdmin.config Team do
        edit do
          field :manager do
            hide
          end
          field :division_id
          field :name
        end
      end
      visit rails_admin_new_path(:model_name => "team")
      should have_selector(".field") do |elements|
        elements[0].should have_selector("#team_division_id")
        elements[1].should have_selector("#team_name")
      end
    end

    it "should be hideable by type" do
      RailsAdmin.config Team do
        edit do
          fields_of_type :string do
            hide
          end
        end
      end
      visit rails_admin_new_path(:model_name => "team")
      should have_selector(".field") do |elements|
        elements.should have_selector("label", :text => "Division")
        elements.should_not have_selector("label", :text => "Name")
        elements.should_not have_selector("label", :text => "Logo url")
        elements.should_not have_selector("label", :text => "Manager")
        elements.should_not have_selector("label", :text => "Ballpark")
        elements.should_not have_selector("label", :text => "Mascot")
        elements.should have_selector("label", :text => "Founded")
        elements.should have_selector("label", :text => "Wins")
        elements.should have_selector("label", :text => "Losses")
        elements.should have_selector("label", :text => "Win percentage")
        elements.should have_selector("label", :text => "Revenue")
        elements.should have_selector("label", :text => "Players")
        elements.should have_selector("label", :text => "Fans")
      end
    end

    it "should be globally hideable by type" do
      RailsAdmin::Config.models do
        edit do
          fields_of_type :string do
            hide
          end
        end
      end
      visit rails_admin_new_path(:model_name => "team")
      should have_selector(".field") do |elements|
        elements.should have_selector("label", :text => "Division")
        elements.should_not have_selector("label", :text => "Name")
        elements.should_not have_selector("label", :text => "Logo url")
        elements.should_not have_selector("label", :text => "Manager")
        elements.should_not have_selector("label", :text => "Ballpark")
        elements.should_not have_selector("label", :text => "Mascot")
        elements.should have_selector("label", :text => "Founded")
        elements.should have_selector("label", :text => "Wins")
        elements.should have_selector("label", :text => "Losses")
        elements.should have_selector("label", :text => "Win percentage")
        elements.should have_selector("label", :text => "Revenue")
        elements.should have_selector("label", :text => "Players")
        elements.should have_selector("label", :text => "Fans")
      end
    end

    it "should have option to customize the help text" do
      RailsAdmin.config Team do
        edit do
          field :manager do
            help "#{help} Additional help text for manager field."
          end
          field :division_id
          field :name
        end
      end
      visit rails_admin_new_path(:model_name => "team")
      should have_selector(".field") do |elements|
        elements[0].should have_selector("p.help", :text => "Required 100 characters or fewer. Additional help text for manager field.")
        elements[1].should have_selector("p.help", :text => "Required")
        elements[2].should have_selector("p.help", :text => "Optional 50 characters or fewer.")
      end
    end

    it "should have option to override required status" do
      RailsAdmin.config Team do
        edit do
          field :manager do
            optional true
          end
          field :division_id do
            optional true
          end
          field :name do
            required true
          end
        end
      end
      visit rails_admin_new_path(:model_name => "team")
      should have_selector(".field") do |elements|
        elements[0].should have_selector("p.help", :text => "Optional 100 characters or fewer.")
        elements[1].should have_selector("p.help", :text => "Optional")
        elements[2].should have_selector("p.help", :text => "Required 50 characters or fewer.")
      end
    end
  end

  describe "input format of" do

    before(:each) do
      RailsAdmin::Config.excluded_models = [RelTest]
      @time = ::Time.now.getutc
    end

    describe "a datetime field" do
      
      it "should default to %B %d, %Y %H:%M" do
        visit rails_admin_new_path(:model_name => "field_test")

        fill_in "field_test[datetime_field]", :with => @time.strftime("%B %d, %Y %H:%M")
        click_button "Save"

        @record = RailsAdmin::AbstractModel.new("FieldTest").first

        @record.datetime_field.strftime("%Y-%m-%d %H:%M").should eql(@time.strftime("%Y-%m-%d %H:%M"))
      end

      it "should have a simple customization option" do
        RailsAdmin.config FieldTest do
          edit do
            field :datetime_field do
              date_format :default
            end
          end
        end

        visit rails_admin_new_path(:model_name => "field_test")

        fill_in "field_test[datetime_field]", :with => @time.strftime("%a, %d %b %Y %H:%M:%S")
        click_button "Save"

        @record = RailsAdmin::AbstractModel.new("FieldTest").first

        @record.datetime_field.should eql(::DateTime.parse(@time.to_s))
      end

      it "should have a customization option" do
        RailsAdmin.config FieldTest do
          list do
            field :datetime_field do
              strftime_format "%Y-%m-%d %H:%M:%S"
            end
          end
        end

        visit rails_admin_new_path(:model_name => "field_test")

        fill_in "field_test[datetime_field]", :with => @time.strftime("%Y-%m-%d %H:%M:%S")
        click_button "Save"

        @record = RailsAdmin::AbstractModel.new("FieldTest").first

        @record.datetime_field.should eql(::DateTime.parse(@time.to_s))
      end
    end

    describe "a timestamp field" do

      it "should default to %B %d, %Y %H:%M" do
        visit rails_admin_new_path(:model_name => "field_test")

        fill_in "field_test[timestamp_field]", :with => @time.strftime("%B %d, %Y %H:%M")
        click_button "Save"

        @record = RailsAdmin::AbstractModel.new("FieldTest").first

        @record.timestamp_field.strftime("%Y-%m-%d %H:%M").should eql(@time.strftime("%Y-%m-%d %H:%M"))
      end

      it "should have a simple customization option" do
        RailsAdmin.config FieldTest do
          edit do
            field :timestamp_field do
              date_format :default
            end
          end
        end

        visit rails_admin_new_path(:model_name => "field_test")

        fill_in "field_test[timestamp_field]", :with => @time.strftime("%a, %d %b %Y %H:%M:%S")
        click_button "Save"

        @record = RailsAdmin::AbstractModel.new("FieldTest").first

        @record.timestamp_field.should eql(::DateTime.parse(@time.to_s))
      end

      it "should have a customization option" do
        RailsAdmin.config FieldTest do
          edit do
            field :timestamp_field do
              strftime_format "%Y-%m-%d %H:%M:%S"
            end
          end
        end

        visit rails_admin_new_path(:model_name => "field_test")

        fill_in "field_test[timestamp_field]", :with => @time.strftime("%Y-%m-%d %H:%M:%S")
        click_button "Save"

        @record = RailsAdmin::AbstractModel.new("FieldTest").first

        @record.timestamp_field.should eql(::DateTime.parse(@time.to_s))
      end
    end
    
    describe " a field with 'format' as a name (Kernel function)" do
      it "should be updatable without any error" do
      
        RailsAdmin.config FieldTest do
          edit do
            field :format
          end
        end

        visit rails_admin_new_path(:model_name => "field_test")
        
        fill_in "field_test[format]", :with => "test for format"
        click_button "Save"

        @record = RailsAdmin::AbstractModel.new("FieldTest").first

        @record.format.should eql("test for format")
      end
    end


    describe "a time field" do

      it "should default to %H:%M" do
        visit rails_admin_new_path(:model_name => "field_test")

        fill_in "field_test[time_field]", :with => @time.strftime("%H:%M")
        click_button "Save"

        @record = RailsAdmin::AbstractModel.new("FieldTest").first

        @record.time_field.strftime("%H:%M").should eql(@time.strftime("%H:%M"))
      end

      it "should have a customization option" do
        RailsAdmin.config FieldTest do
          edit do
            field :time_field do
              strftime_format "%I:%M %p"
            end
          end
        end

        visit rails_admin_new_path(:model_name => "field_test")

        fill_in "field_test[time_field]", :with => @time.strftime("%I:%M %p")
        click_button "Save"

        @record = RailsAdmin::AbstractModel.new("FieldTest").first

        @record.time_field.strftime("%H:%M").should eql(@time.strftime("%H:%M"))
      end
    end

    describe "a date field" do

      it "should default to %B %d, %Y" do
        visit rails_admin_new_path(:model_name => "field_test")

        fill_in "field_test[date_field]", :with => @time.strftime("%B %d, %Y")
        click_button "Save"

        @record = RailsAdmin::AbstractModel.new("FieldTest").first

        @record.date_field.should eql(::Date.parse(@time.to_s))
      end


      it "should have a simple customization option" do
        RailsAdmin.config FieldTest do
          edit do
            field :date_field do
              date_format :default
            end
          end
        end

        visit rails_admin_new_path(:model_name => "field_test")

        fill_in "field_test[date_field]", :with => @time.strftime("%Y-%m-%d")
        click_button "Save"

        @record = RailsAdmin::AbstractModel.new("FieldTest").first

        @record.date_field.should eql(::Date.parse(@time.to_s))
      end

      it "should have a customization option" do
        RailsAdmin.config FieldTest do
          edit do
            field :date_field do
              strftime_format "%Y-%m-%d"
            end
          end
        end

        visit rails_admin_new_path(:model_name => "field_test")

        fill_in "field_test[date_field]", :with => @time.strftime("%Y-%m-%d")
        click_button "Save"

        @record = RailsAdmin::AbstractModel.new("FieldTest").first

        @record.date_field.should eql(::Date.parse(@time.to_s))
      end
    end
  end

  describe "fields which are nullable and have AR validations" do
    it "should be required" do
      # draft.notes is nullable and has no validation
      field = RailsAdmin::config("Draft").edit.fields.find{|f| f.name == :notes}
      field.properties[:nullable?].should be true
      field.required?.should be false

      # draft.date is nullable in the schema but has an AR
      # validates_presence_of validation that makes it required
      field = RailsAdmin::config("Draft").edit.fields.find{|f| f.name == :date}
      field.properties[:nullable?].should be true
      field.required?.should be true

      # draft.round is nullable in the schema but has an AR
      # validates_numericality_of validation that makes it required
      field = RailsAdmin::config("Draft").edit.fields.find{|f| f.name == :round}
      field.properties[:nullable?].should be true
      field.required?.should be true

      # team.revenue is nullable in the schema but has an AR
      # validates_numericality_of validation that allows nil
      field = RailsAdmin::config("Team").edit.fields.find{|f| f.name == :revenue}
      field.properties[:nullable?].should be true
      field.required?.should be false
    end
  end
  
  
  describe "CKEditor Support" do
    it "should start with CKEditor disabled" do
       field = RailsAdmin::config("Draft").edit.fields.find{|f| f.name == :notes}
       field.ckeditor.should be false
    end

    it "should add Javascript to enable CKEditor" do
      RailsAdmin.config Draft do
        edit do
          field :notes do
            ckeditor true
          end
        end
      end

      visit rails_admin_new_path(:model_name => "draft")
      should have_selector("script", :text => /CKEDITOR\.replace.*?draft_notes/)
    end
  end

  describe "Paperclip Support" do

    it "should show a file upload field" do
      RailsAdmin.config User do
        edit do
          field :avatar
        end
      end
      visit rails_admin_new_path(:model_name => "user")
      should have_selector("input#user_avatar")
    end

  end
  
  describe "Enum field support" do
    it "should auto-detect enumeration when object responds to '\#{method}_enum'" do
      class Team
        def color_enum
          ["blue", "green", "red"]
        end
      end
      
      RailsAdmin.config Team do
        edit do
          field :color
        end
      end
      visit rails_admin_new_path(:model_name => "team")
      should have_selector("select.enum")
      should have_content("green")
      
      #Reset
      Team.send(:remove_method, :color_enum)  
      RailsAdmin::Config.reset Team
    end
    
    it "should allow configuration of the enum method" do
      class Team
        def color_list
          ["blue", "green", "red"]
        end
      end
      
      RailsAdmin.config Team do
        edit do
          field :color, :enum do
            enum_method :color_list
          end
        end
      end
      visit rails_admin_new_path(:model_name => "team")
      should have_selector("select.enum")
      should have_content("green")
      
      #Reset
      Team.send(:remove_method, :color_list)
      RailsAdmin::Config.reset Team
    end
    
    it "should allow direct listing of enumeration options and override enum method" do
      class Team
        def color_list
          ["blue", "green", "red"]
        end
      end
      
      RailsAdmin.config Team do
        edit do
          field :color, :enum do
            enum_method :color_list
            enum do
              ["yellow", "black"]
            end
          end
        end
      end
      
      visit rails_admin_new_path(:model_name => "team")
      should have_selector("select.enum")
      should have_no_content("green")
      should have_content("yellow")
    
      #Reset
      Team.send(:remove_method, :color_list)
      RailsAdmin::Config.reset Team
    end

  end
  
  describe "ColorPicker Support" do
    it "should show input with class color" do
      RailsAdmin.config Team do
        edit do
          field :color do
            color true
          end
        end
      end
      visit rails_admin_new_path(:model_name => "team")
      should have_selector("input.color")
    end
  end

  describe "Form builder configuration" do

    it "should allow override of default" do
      RailsAdmin.config do |config|
        config.model Player do
          edit do
            field :name
          end
        end
        config.model Team do
          edit do
            form_builder :form_for_edit
            field :name
          end
        end
        config.model Fan do
          create do
            form_builder :form_for_create
            field :name
          end
          update do
            form_builder :form_for_update
            field :name
          end
        end
        config.model League do
          create do
            form_builder :form_for_league_create
            field :name
          end
          update do
            field :name
          end
        end
      end

      RailsAdmin::Config.model(Player).create.form_builder.should be(:form_for)
      RailsAdmin::Config.model(Player).update.form_builder.should be(:form_for)
      RailsAdmin::Config.model(Player).edit.form_builder.should be(:form_for)

      RailsAdmin::Config.model(Team).update.form_builder.should be(:form_for_edit)
      RailsAdmin::Config.model(Team).create.form_builder.should be(:form_for_edit)
      RailsAdmin::Config.model(Team).edit.form_builder.should be(:form_for_edit)

      RailsAdmin::Config.model(Fan).create.form_builder.should be(:form_for_create)
      RailsAdmin::Config.model(Fan).update.form_builder.should be(:form_for_update)
      RailsAdmin::Config.model(Fan).edit.form_builder.should be(:form_for_update) # not sure we care

      RailsAdmin::Config.model(League).create.form_builder.should be(:form_for_league_create)
      RailsAdmin::Config.model(League).update.form_builder.should be(:form_for)
      RailsAdmin::Config.model(League).edit.form_builder.should be(:form_for) # not sure we care

      # don't spill over into other views
      expect {
        RailsAdmin::Config.model(Team).list.form_builder
      }.to raise_error(NoMethodError,/undefined method/)
    end

    it "should be used in the new and edit views" do
      TF_CREATE_OUTPUT = "MY TEST FORM CREATE TEXT FIELD"
      TF_UPDATE_OUTPUT = "MY TEST FORM UPDATE TEXT FIELD"

      module MyCreateForm
        class Builder < ::ActionView::Helpers::FormBuilder
          def text_field(*args)
            TF_CREATE_OUTPUT
          end
        end

        module ViewHelper
          def create_form_for(*args, &block)
            options = args.extract_options!.reverse_merge(:builder => MyCreateForm::Builder)
            form_for(*(args << options), &block)
          end
        end
      end

      module MyUpdateForm
        class Builder < ::ActionView::Helpers::FormBuilder
          def text_field(*args)
            TF_UPDATE_OUTPUT
          end
        end

        module ViewHelper
          def update_form_for(*args, &block)
            options = args.extract_options!.reverse_merge(:builder => MyUpdateForm::Builder)
            form_for(*(args << options), &block)
          end
        end
      end

      class ActionView::Base
        include MyCreateForm::ViewHelper
        include MyUpdateForm::ViewHelper
      end

      RailsAdmin.config do |config|
        config.model Player do
          edit do
            field :name
          end
        end
        config.model Team do
          edit do
            form_builder :create_form_for
            field :name
          end
        end
        config.model League do
          create do
            form_builder :create_form_for
            field :name
          end
          update do
            form_builder :update_form_for
            field :name
          end
        end
      end

      visit rails_admin_new_path(:model_name => "player")
      should have_selector("input#player_name")
      should have_no_content(TF_CREATE_OUTPUT)
      should have_no_content(TF_UPDATE_OUTPUT)
      @player = FactoryGirl.create :player
      visit rails_admin_edit_path(:model_name => "player", :id => @player.id)
      should have_selector("input#player_name")
      should have_no_content(TF_CREATE_OUTPUT)
      should have_no_content(TF_UPDATE_OUTPUT)

      visit rails_admin_new_path(:model_name => "team")
      should have_content(TF_CREATE_OUTPUT)
      should have_no_content(TF_UPDATE_OUTPUT)
      @team = FactoryGirl.create :team
      visit rails_admin_edit_path(:model_name => "team", :id => @team.id)
      should have_content(TF_CREATE_OUTPUT)
      should have_no_content(TF_UPDATE_OUTPUT)

      visit rails_admin_new_path(:model_name => "league")
      should have_content(TF_CREATE_OUTPUT)
      should have_no_content(TF_UPDATE_OUTPUT)
      @league = FactoryGirl.create :league
      visit rails_admin_edit_path(:model_name => "league", :id => @league.id)
      should have_no_content(TF_CREATE_OUTPUT)
      should have_content(TF_UPDATE_OUTPUT)
    end

  end

end
