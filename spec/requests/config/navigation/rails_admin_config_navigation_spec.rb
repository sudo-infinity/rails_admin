require 'spec_helper'

describe "RailsAdmin Config DSL Navigation Section" do

  subject { page }

  describe "number of visible tabs" do
    after(:each) do
      RailsAdmin.config do |config|
        config.navigation.max_visible_tabs 5
      end
    end

    it "should be editable" do
      RailsAdmin.config do |config|
        config.navigation.max_visible_tabs 2
      end
      visit rails_admin_dashboard_path
      should have_selector("#nav > li") do |elements|
        elements.should have_at_most(4).items
      end
    end
  end
  
  describe "order of items" do
    after(:each) do
      RailsAdmin.config do |config|
        config.navigation.max_visible_tabs 5
        config.model Team do
          weight 0
        end
        config.model Comment do
          parent :root
        end
        config.model Cms::BasicPage do
          dropdown nil
          weight 0
        end
      end
    end

    it "should be alphabetical by default" do
      RailsAdmin.config do |config|
        config.navigation.max_visible_tabs 20
      end
      visit rails_admin_dashboard_path
      should have_selector("#nav>li>a") do |as|
        as.map(&:content)[1..-1].should == ["Cms/Basic Pages", "Comments", "Divisions", "Drafts", "Fans", "Leagues", "Players", "Teams", "Users"]
      end
    end
    
    it "should be ordered by weight and alphabetical order" do
      RailsAdmin.config do |config|
        config.navigation.max_visible_tabs 20
        config.model Team do
          weight -1
        end
      end
      visit rails_admin_dashboard_path
      should have_selector("#nav>li>a") do |as|
        as.map(&:content)[1..-1].should == ["Teams", "Cms/Basic Pages", "Comments", "Divisions", "Drafts", "Fans", "Leagues", "Players", "Users"]
      end
    end
    
    it "should nest menu items with parent and not take max_visible_tabs into account" do
      RailsAdmin.config do |config|
        config.navigation.max_visible_tabs 3
        config.model Comment do
          parent Cms::BasicPage
        end
      end
      visit rails_admin_dashboard_path
      should have_selector("#nav>li>a") do |as|
        as.map(&:content)[1..-1].should == ["Cms/Basic Pages", "Divisions", "Drafts", "Fans", "Leagues", "Players", "Teams", "Users"]
      end
      should have_selector("#nav>li.more>ul>li>a") do |as|
        as.map(&:content).should == ["Cms/Basic Pages", "Comments"]
      end
    end

    it "should override parent label with dropdown" do
      RailsAdmin.config do |config|
        config.model Comment do
          parent Cms::BasicPage
        end
        config.model Cms::BasicPage do
          dropdown "CMS related"
        end
      end
      visit rails_admin_dashboard_path
      should have_selector("#nav>li>a") do |as|
        as.map(&:content)[1..-1].should == ["CMS related", "Divisions", "Drafts", "Fans", "Leagues", "Players", "Teams", "Users"]
      end
      should have_selector("#nav>li.more>ul>li>a") do |as|
        as.map(&:content).should == ["Cms/Basic Pages", "Comments"]
      end
    end
    
    it "should order dropdown item according to parent weight" do
      RailsAdmin.config do |config|
        config.model Comment do
          parent Cms::BasicPage
        end
        config.model Cms::BasicPage do
          dropdown "CMS related"
          weight 1
        end
      end
      visit rails_admin_dashboard_path
      should have_selector("#nav>li>a") do |as|
        as.map(&:content)[1..-1].should == ["Divisions", "Drafts", "Fans", "Leagues", "Players", "Teams", "Users", "CMS related"]
      end
    end
  end

  describe "label for a model" do

    it "should be visible and sane by default" do
      visit rails_admin_dashboard_path
      should have_selector("#nav") do |navigation|
        navigation.should have_selector("li a", :text => "Fan")
      end
    end

    it "should be editable" do
      RailsAdmin.config Fan do
        label "Fan test 1"
      end
      visit rails_admin_dashboard_path
      should have_selector("#nav") do |navigation|
        navigation.should have_selector("li a", :text => "Fan test 1")
      end
    end

    it "should be hideable" do
      RailsAdmin.config Fan do
        hide
      end
      visit rails_admin_dashboard_path
      should have_selector("#nav") do |navigation|
        navigation.should_not have_selector("li a", :text => "Fan")
      end
    end
  end
end
