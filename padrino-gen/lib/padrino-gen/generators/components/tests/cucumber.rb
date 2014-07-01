apply_component_for(:rspec, :test)

CUCUMBER_SETUP = (<<-TEST) unless defined?(CUCUMBER_SETUP)
RACK_ENV = 'test' unless defined?(RACK_ENV)
require File.expand_path(File.dirname(__FILE__) + "/../../config/boot")
Dir[File.expand_path(File.dirname(__FILE__) + "/../app/helpers/**/*.rb")].each(&method(:require))

require 'capybara/cucumber'
require 'rspec/expectations'

##
# You can handle all padrino applications using instead:
#   Padrino.application
Capybara.app = CLASS_NAME.tap { |app|  }
TEST

CUCUMBER_YML = (<<-TEST) unless defined?(CUCUMBER_YML)
default: --tags ~@wip --strict features
html_report: --tags ~@wip --strict --format html --out=features_report.html features
TEST

CUCUMBER_FEATURE = (<<-TEST) unless defined?(CUCUMBER_FEATURE)
Feature: Addition
  In order to avoid silly mistakes
  As a math idiot
  I want to be told the sum of two numbers

  Scenario: Add two numbers
    Given I visit the calculator page
    And I fill in '50' for 'first'
    And I fill in '70' for 'second'
    When I press 'Add'
    Then I should see 'Answer: 120'
TEST

CUCUMBER_STEP = (<<-TEST) unless defined?(CUCUMBER_STEP)
Given /^I visit the calculator page$/ do
  visit '/add'
end

Given /^I fill in '(.*)' for '(.*)'$/ do |value, field|
  fill_in(field, :with => value)
end

When /^I press '(.*)'$/ do |name|
  click_button(name)
end

Then /^I should see '(.*)'$/ do |text|
  page.should have_content(text)
end
TEST

CUCUMBER_URL = (<<-TEST) unless defined?(CUCUMBER_URL)
module Cucumber
  module Web
    module URLs
      def url_for(*names)
        Capybara.app.url_for(*names)
      end
      alias_method :url, :url_for

      def absolute_url_for(*names)
        "http://www.example.com" + Capybara.app.url_for(*names)
      end
      alias_method :absolute_url, :absolute_url_for
    end
  end
end

World(Cucumber::Web::URLs)
TEST

def setup_test
  require_dependencies 'rack-test', :require => 'rack/test', :group => 'test'
  require_dependencies 'cucumber', :group => 'test'
  require_dependencies 'capybara', :group => 'test'
  insert_test_suite_setup CUCUMBER_SETUP, :path => "features/support/env.rb"
  create_file destination_root("features/support/url.rb"), CUCUMBER_URL
  create_file destination_root("features/add.feature"), CUCUMBER_FEATURE
  create_file destination_root("features/step_definitions/add_steps.rb"), CUCUMBER_STEP
  create_file destination_root("cucumber.yml"), CUCUMBER_YML
  require_dependencies 'rspec', :group => 'test'
  insert_test_suite_setup RSPEC_SETUP, :path => "spec/spec_helper.rb"
  create_file destination_root("spec/spec.rake"), RSPEC_RAKE
end
