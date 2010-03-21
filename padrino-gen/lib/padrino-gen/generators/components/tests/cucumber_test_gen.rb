require 'padrino-gen/generators/components/tests/rspec_test_gen'

module Padrino
  module Generators
    module Components
      module Tests

        module CucumberGen
          include Padrino::Generators::Components::Tests::RspecGen

          CUCUMBER_SETUP = (<<-TEST).gsub(/^ {10}/, '')
          PADRINO_ENV = 'test' unless defined?(PADRINO_ENV)
          require File.dirname(__FILE__) + "/../../config/boot"

          require 'capybara/cucumber'
          require 'spec/expectations'

          # Sinatra < 1.0 always disable sessions for test env
          # so if you need them it's necessary to force the use
          # of Rack::Session::Cookie
          Capybara.app = CLASS_NAME.tap { |app| app.use Rack::Session::Cookie }
          # You can handle all padrino applications instead using:
          #   Capybara.app = Padrino.application
          TEST

          CUCUMBER_YML = (<<-TEST).gsub(/^ {10}/, '')
          default: --tags ~@wip --strict features
          html_report: --tags ~@wip --strict --format html --out=features_report.html features
          TEST

          CUCUMBER_FEATURE = (<<-TEST).gsub(/^ {10}/, '')
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

          CUCUMBER_STEP = (<<-TEST).gsub(/^ {10}/, '')
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
            response_body.should contain(/#\{text}/m)
          end
          TEST

          def setup_test_with_cucumber
            require_dependencies 'cucumber', :group => 'test'
            require_dependencies 'capybara', :group => 'test'
            insert_test_suite_setup CUCUMBER_SETUP, :path => "features/support/env.rb"
            create_file destination_root("features/add.feature"), CUCUMBER_FEATURE
            create_file destination_root("features/step_definitions/add_steps.rb"), CUCUMBER_STEP
            create_file destination_root("cucumber.yml"), CUCUMBER_YML
            setup_test_without_cucumber
          end

          alias_method_chain :setup_test, :cucumber
        end # CucumberGen
      end # Tests
    end # Components
  end # Generators
end # Padrino