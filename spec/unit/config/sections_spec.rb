require 'spec_helper'

describe RailsAdmin::Config::Sections do

  describe "configure" do
    it "should configure without changing the section default list" do
      RailsAdmin.config Team do
        edit do
          configure :name do
            label "Renamed"
          end
        end
      end
      fields = RailsAdmin.config(Team).edit.fields
      expect(fields.find{|f| f.name == :name }.label).to eq("Renamed")
      expect(fields.count).to be >= 19 # not 1
    end

    it "should not change the section list if set" do
      RailsAdmin.config Team do
        edit do
          field :manager
          configure :name do
            label "Renamed"
          end
        end
      end
      fields = RailsAdmin.config(Team).edit.fields
      expect(fields.first.name).to eq(:manager)
      expect(fields.count).to eq(1) # not 19
    end
  end

  describe "DSL field inheritance" do
    it "should be tested" do
      RailsAdmin.config do |config|
        config.model Fan do
          field :name do
            label do
              @label ||= "modified base #{label}"
            end
          end
          list do
            field :name do
              label do
                @label ||= "modified list #{label}"
              end
            end
          end
          edit do
            field :name do
              label do
                @label ||= "modified edit #{label}"
              end
            end
          end
          create do
            field :name do
              label do
                @label ||= "modified create #{label}"
              end
            end
          end
        end

      end
      expect(RailsAdmin.config(Fan).visible_fields.count).to eq(1)
      expect(RailsAdmin.config(Fan).visible_fields.first.label).to eq('modified base His Name')
      expect(RailsAdmin.config(Fan).list.visible_fields.first.label).to eq('modified list His Name')
      expect(RailsAdmin.config(Fan).export.visible_fields.first.label).to eq('modified base His Name')
      expect(RailsAdmin.config(Fan).edit.visible_fields.first.label).to eq('modified edit His Name')
      expect(RailsAdmin.config(Fan).create.visible_fields.first.label).to eq('modified create His Name')
      expect(RailsAdmin.config(Fan).update.visible_fields.first.label).to eq('modified edit His Name')
    end
  end

  describe "DSL group inheritance" do
    it "should be tested" do
      RailsAdmin.config do |config|
        config.model Team do
          list do
            group "a" do
              field :founded
            end

            group "b" do
              field :name
              field :wins
            end
          end

          edit do
            group "a" do
              field :name
            end

            group "c" do
              field :founded
              field :wins
            end
          end

          update do
            group "d" do
              field :wins
            end

            group "e" do
              field :losses
            end
          end
        end
      end

      expect(RailsAdmin.config(Team).list.visible_groups.map{|g| g.visible_fields.map(&:name) }).to eq([[:founded], [:name, :wins]])
      expect(RailsAdmin.config(Team).edit.visible_groups.map{|g| g.visible_fields.map(&:name) }).to eq([[:name], [:founded, :wins]])
      expect(RailsAdmin.config(Team).create.visible_groups.map{|g| g.visible_fields.map(&:name) }).to eq([[:name], [:founded, :wins]])
      expect(RailsAdmin.config(Team).update.visible_groups.map{|g| g.visible_fields.map(&:name) }).to eq([[:name], [:founded], [:wins], [:losses]])
      expect(RailsAdmin.config(Team).visible_groups.map{|g| g.visible_fields.map(&:name) }.flatten.count).to eq(19)
      expect(RailsAdmin.config(Team).export.visible_groups.map{|g| g.visible_fields.map(&:name) }.flatten.count).to eq(19)
    end
  end
end
