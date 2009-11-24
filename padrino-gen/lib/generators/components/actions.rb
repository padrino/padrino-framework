module Padrino
  module Generators
    module Components
      module Actions
        BASE_TEST_HELPER = (<<-TEST).gsub(/^ {8}/, '')
        RACK_ENV = 'test' unless defined?(RACK_ENV)
        require File.dirname(__FILE__) + "/../config/boot"
        Bundler.require_env(:testing)
        TEST

        # Adds all the specified gems into the Gemfile for bundler
        # require_dependencies 'activerecord'
        # require_dependencies 'mocha', 'bacon', :env => :testing
        def require_dependencies(*gem_names)
          options = gem_names.extract_options!
          gem_names.reverse.each { |lib| insert_into_gemfile(lib, options) }
        end

        # Inserts a required gem into the Gemfile to add the bundler dependency
        # insert_into_gemfile(name)
        # insert_into_gemfile(name, :env => :testing, :require_as => 'foo')
        def insert_into_gemfile(name, options={})
          after_pattern = options[:env] ? "#{options[:env].to_s.capitalize} requirements\n" : "Component requirements\n"
          gem_options = options.slice(:env, :require_as).collect { |k, v| "#{k.inspect} => #{v.inspect}" }.join(", ")
          include_text = "gem '#{name}'" << (gem_options.present? ? ", #{gem_options}" : "") << "\n"
          options.merge!(:content => include_text, :after => after_pattern)
          inject_into_file('Gemfile', options[:content], :after => options[:after])
        end

        # Injects the test class text into the test_config file for setting up the test gen
        # insert_test_suite_setup('...CLASS_NAME...')
        # => inject_into_file("test/test_config.rb", TEST.gsub(/CLASS_NAME/, @class_name), :after => "set :environment, :test\n")
        def insert_test_suite_setup(suite_text, options={})
          test_helper_text = [BASE_TEST_HELPER, suite_text.gsub(/CLASS_NAME/, @class_name)].join("\n")
          options.reverse_merge!(:path => "test/test_config.rb")
          create_file(options[:path], test_helper_text)
        end

        # Injects the mock library include into the test class in test_config for setting up mock gen
        # insert_mock_library_include('Mocha::API')
        # => inject_into_file("test/test_config.rb", "  include Mocha::API\n", :after => /class.*?\n/)
        def insert_mocking_include(library_name, options={})
          options.reverse_merge!(:indent => 2, :after => /class.*?\n/, :path => "test/test_config.rb")
          return unless File.exist?(File.join(self.destination_root, options[:path]))
          include_text = indent_spaces(options[:indent]) + "include #{library_name}\n"
          inject_into_file(options[:path], include_text, :after => options[:after])
        end

        # Returns space characters of given count
        # indent_spaces(2)
        def indent_spaces(count)
          ' ' * count
        end
      end
    end
  end
end
