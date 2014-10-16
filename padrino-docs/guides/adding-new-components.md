---
date: 2010-04-06
author: Nathan
email: nesquena@gmail.com
title: Adding New Components
---

Padrino is an agnostic web framework. This means that the framework has been built from the ground up to easily allow support for any arbitrary number of different developer choices with respect to object permanance, stylesheet templaters, javascript libraries, testing libraries, mocking libraries and rendering engines. For a detailed overview of the available components, check out the [generators guide](/guides/generators).

Although Padrino is fundamentally agnostic, in practice only a very limited set of available components have actually been integrated into the Padrino generator and admin dashboard. The set of available components is determined by libraries actually used or noted by the core developers and the existing community. However, adding additional components to Padrino is not only possible but highly recommended. In fact, this is possibly *the best* way for a developer to get started [contributing to Padrino](http://www.padrinorb.com/pages/contribute).

This guide will outline in detail how to properly contribute new components to Padrino and get them included into the next Padrino generator as quickly and efficiently as possible.

 

## Persistence Engine

Contributing an object persistence library is probably the most involved component to integrate with Padrino. For this guide, let us pretend that we would like to integrate `Datamapper` into Padrino. First, let’s add `Datamapper` to the project generator’s available components in [padrino-gen/generators/project.rb](http://github.com/padrino/padrino-framework/blob/master/padrino-gen/lib/padrino-gen/generators/project.rb#L28):

    # padrino-gen/lib/padrino-gen/generators/project.rb
    component_option :orm, "database engine", :choices => [:activerecord, :datamapper]

Here, we needed to append `:datamapper` as an option for the `:orm` component\_option in the project generator. Once we have defined datamapper as an option for the orm component, let’s actually define the specific integration tasks for the generator in [padrino-gen/generators/components/orms/datamapper.rb](http://github.com/padrino/padrino-framework/blob/master/padrino-gen/lib/padrino-gen/generators/components/orms/datamapper.rb):

    # padrino-gen/lib/padrino-gen/generators/components/orms/datamapper.rb
    # These are the steps to setup the persistence layer in the initial project
    # such as requiring certain gems, constructing the database.rb configuration file
    # and creating the models folder for the application
    def setup_orm
      require_dependencies 'data_objects', 'do_sqlite3', 'datamapper'
      create_file("config/database.rb", DM)
      empty_directory('app/models')
    end

    # These are the steps to generate the actual model file 
    # when the model generator is executed.
    # 
    # create_model_file("account", ["username:string", "password:string"])
    def create_model_file(name, fields)
      # ...truncated...
      create_file(model_path, model_contents)
    end

    # These are the steps to generate the model migration file 
    # when the model generator is executed.
    # 
    # create_model_migration("create_accounts", "account", ["username:string"])
    def create_model_migration(migration_name, name, columns)
      # ...truncated...
    end

    # These are the steps to generate the db migration file 
    # when the migration generator is executed.
    #
    # create_migration_file("AddEmailToAccount", "AddEmailToAccount", ["email:string"])
    def create_migration_file(migration_name, name, columns)
      # ...truncated...
    end

Next, if the persistence engine needs to include useful rake tasks (to migrate or modify the database for instance), you can add these to the `padrino-tasks` folder in the `padrino-gen` gem. For Datamapper, there are a number of tasks that should be available in [padrino-tasks/datamapper.rb](http://github.com/padrino/padrino-framework/blob/master/padrino-gen/lib/padrino-gen/padrino-tasks/datamapper.rb):

    # padrino-gen/lib/padrino-gen/padrino-tasks/datamapper.rb
    if defined?(DataMapper)
      namespace :dm do
        namespace :migrate do
          task :load => :environment do
            # ...truncated...
          end
          
          desc "Migrate up using migrations"
          task :up, :version, :needs => :load do |t, args|
            # ...truncated...
          end
        end
      end
    end

Next, let’s add the appropriate unit tests to ensure our new component works as intended in [padrino-gen/test/test\_project\_generator.rb](http://github.com/padrino/padrino-framework/blob/master/padrino-gen/test/test_project_generator.rb#L129):

    # padrino-gen/test/test_project_generator.rb
    should "properly generate default for datamapper" do
      buffer = silence_logger {@project.start(['sample_project', '--root=/tmp', '--orm=datamapper'])}
      assert_match /Applying.*?datamapper.*?orm/, buffer
      assert_match_in_file(/gem 'data_objects'/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/gem 'datamapper'/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/DataMapper.setup/, '/tmp/sample_project/config/database.rb')
      assert_dir_exists('/tmp/sample_project/app/models')
    end

Finally for the generator integration, we should add the available option to the [generator README file](http://github.com/padrino/padrino-framework/blob/master/padrino-gen/README.rdoc):

    # padrino-gen/README.rdoc
    orm:: none  (default), mongomapper, mongoid, activerecord, sequel, couchrest, datamapper

and with that update to the README, persistence support for the generator is complete. However, to be fully compliant, support for Padrino Admin should also be added. This will allow the admin dashboard to work properly with your persistence engine of choice and is **highly** recommended.

Adding `padrino-admin` support for your persistence engine is actually fairly straightforward. First, let’s add `Datamapper` to the set of supported admin orm engines in [padrino-admin/generators/actions.rb](http://github.com/padrino/padrino-framework/blob/master/padrino-admin/lib/padrino-admin/generators/actions.rb#L17):

    # padrino-admin/lib/padrino-admin/generators/actions.rb
    def supported_orm
      [:activerecord, :mongomapper, :mongoid, :couchrest, :datamapper]
    end

Next, we need to define the interaction methods available by our persistence engine on our models in [padrino-admin/generators/orm.rb](http://github.com/padrino/padrino-framework/blob/master/padrino-admin/lib/padrino-admin/generators/orm.rb):

    # padrino-admin/lib/padrino-admin/generators/orm.rb
    module Padrino
      module Admin
        module Generators
          class OrmError < StandardError; end
          class Orm
            attr_reader :klass_name, :klass, :name_plural, :name_singular, :orm

            def initialize(name, orm, columns=nil, column_fields=nil)
              # ...truncated...
            end

            # Defines access to a model's columns
            def columns
              @columns ||= case orm
                when :activerecord then @klass.columns
                when :datamapper   then @klass.properties
                else raise OrmError, "Adapter #{orm} is not yet supported!"
              end
            end
     
            # Defines access to retrieving all existing records for a model.
            def all
              "#{klass_name}.all"
            end

            # Defines access for querying records for a model.
            def find(params=nil)
              case orm
                when :activerecord then "#{klass_name}.find(#{params})"
                when :datamapper   then "#{klass_name}.get(#{params})"
                else raise OrmError, "Adapter #{orm} is not yet supported!"
              end
            end

            # Defines how to build a new record for a model.
            def build(params=nil)
              if params
                "#{klass_name}.new(#{params})"
              else
                "#{klass_name}.new"
              end
            end

            # Defines how to save a new record for a model.
            def save
              "#{name_singular}.save"
            end

            # Defines how to update attributes of a record for a model.
            def update_attributes(params=nil)
              case orm
                when :activerecord then "#{name_singular}.update_attributes(#{params})"
                when :datamapper then "#{name_singular}.update(#{params})"
                else raise OrmError, "Adapter #{orm} is not yet supported!"
              end
            end

            # Defines how to destroy a record for a model.
            def destroy
              "#{name_singular}.destroy"
            end
          end # Orm
        end # Generators
      end # Admin
    end # Padrino

Next, we need to describe how the `Account` model should be defined for our persistence engine within [padrino-admin/generators/templates/account/datamapper.rb.tt](http://github.com/padrino/padrino-framework/blob/master/padrino-admin/lib/padrino-admin/generators/templates/account/datamapper.rb.tt):

    # padrino-admin/lib/padrino-admin/generators/templates/account/datamapper.rb.tt
    class Account
      include DataMapper::Resource
      include DataMapper::Validate
      attr_accessor :password, :password_confirmation
     
      # Define Properties
      property :id,               Serial
      property :name,             String
      # ...truncated...
     
      # Define Validations
      validates_present      :email, :role
      # ...truncated...
     
      # Callbacks
      before :save, :generate_password
     
      ##
      # This method is for authentication purpose
      #
      def self.authenticate(email, password)
        account = first(:conditions => { :email => email }) if email.present?
        account && account.password_clean == password ? account : nil
      end
     
      ##
      # This method is used from AuthenticationHelper
      #
      def self.find_by_id(id)
        get(id) rescue nil
      end
     
      ##
      # This method is used for retrive the original password.
      #
      def password_clean
        crypted_password.decrypt(salt)
      end
     
      private
        def generate_password
          return if password.blank?
          self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{email}--") if new?
          self.crypted_password = password.encrypt(self.salt)
        end
     
        def password_required
          crypted_password.blank? || !password.blank?
        end
    end

Finally, let’s update the `padrino-admin` README file at [padrino-admin/README.rdoc](http://github.com/padrino/padrino-framework/blob/master/padrino-admin/README.rdoc) to reflect our newly support component:

    # padrino-admin/README.rdoc
    Orm Agnostic:: Data Adapters for Datamapper, Activerecord, Mongomapper, Mongoid, Couchrest

This completes the full integration of a persistence engine into Padrino. Once all of this has been finished in your github fork, send us a pull request and assuming you followed these instructions properly and the engine actually works when generated, we will include the component into the next Padrino version crediting you for the contribution!

 

## Javascript Library

Contributing an additional javascript library to Padrino is actually quite straightforward. For this guide, let’s assume we want to add `extcore` as a javascript component integrated into Padrino. First, let’s add `extcore` to the project generator’s available components in [padrino-gen/generators/project.rb](http://github.com/padrino/padrino-framework/blob/master/padrino-gen/lib/padrino-gen/generators/project.rb#L31):

    # padrino-gen/lib/padrino-gen/generators/project.rb
    component_option :script, "javascript library", :choices => [:jquery, :prototype, :extcore]

Next, let’s define the actual integration of the javascript into the generator in [padrino-gen/generators/components/scripts/extcore.rb](http://github.com/padrino/padrino-framework/blob/master/padrino-gen/lib/padrino-gen/generators/components/scripts/extcore.rb):

    # padrino-gen/lib/padrino-gen/generators/components/scripts/extcore.rb
    def setup_script
      copy_file('templates/scripts/ext-core.js', destination_root("/public/javascripts/ext-core.js"))
      create_file(destination_root('/public/javascripts/application.js'), "// Put scripts here")
    end

This will copy the script into the `public/javascripts` folder of a newly generated project and construct the `application.js` file. Next, let’s copy the latest version of the javascript library to the templates folder:

    # padrino-gen/lib/padrino-gen/generators/templates/scripts/ext-core.js
    # ...truncated javascript library code here...

Let’s also add a test to ensure the new javascript component generates as expected in [padrino-gen/test/test\_project\_generator.rb](http://github.com/padrino/padrino-framework/blob/master/padrino-gen/test/test_project_generator.rb#L198):

    # padrino-gen/test/test_project_generator.rb
    should "properly generate for ext-core" do
      buffer = silence_logger{@project.start(['sample_project', '--root=/tmp', '--script=extcore'])}
      assert_match /Applying.*?extcore.*?script/, buffer   
      assert_file_exists('/tmp/sample_project/public/javascripts/ext-core.js')
      assert_file_exists('/tmp/sample_project/public/javascripts/application.js'  
    end

and finally let’s update the README for `padrino-gen` to reflect the new component in [padrino-gen/README.rdoc](http://github.com/padrino/padrino-framework/blob/master/padrino-gen/README.rdoc):

    # padrino-gen/README.rdoc
    script:: none  (default), jquery, prototype, mootools, rightjs, extcore

This completes the full integration of a javascript library into Padrino. Once all of this has been finished in your github fork, send us a pull request and assuming you followed these instructions properly and the library actually works when generated, we will include the component into the next Padrino version crediting you for the contribution!

An example of the [actual commit](http://github.com/padrino/padrino-framework/commit/43fb57dd39fa9d860873c14840e68281e314abb8) of the `extcore` javascript library is a great example of how to contribute to Padrino.

In addition to this, you can also provide a UJS adapter which provides ‘remote’ and ‘method’ support to a project using a particular javascript framework. For more information about UJS, check out the [UJS Helpers](http://www.padrinorb.com/guides/application-helpers#unobtrusive-javascript-helpers) guide.

To support UJS in a given javascript framework, simply create a new file such as ‘jquery-ujs’ in your [padrino-static](https://github.com/padrino/padrino-static) fork and then follow the UJS [adapter template](https://github.com/padrino/padrino-static/blob/master/ujs/jquery-ujs.js) used by the existing implementation.

    // ujs/jquery-ujs.js
    /* Remote Form Support
     * form_for @user, '/user', :remote => true
    **/
    $("form[data-remote=true]").live('submit', function(e) {
      // ...
    });
    /* Confirmation Support
     * link_to 'sign out', '/logout', :confirm => "Log out?"
     * Link Remote Support 
     * link_to 'add item', '/create', :remote => true
     * Link Method Support
     * link_to 'delete item', '/destroy', :method => :delete
    **/

    /* JSAdapter */
    var JSAdapter = {
      // Sends an xhr request to the specified url with given verb and params
      // JSAdapter.sendRequest(element, { verb: 'put', url : '...', params: {} });
      sendRequest : function(element, options) {
        // ...
      },
      // Triggers a particular method verb to be triggered in a form posting to the url
      // JSAdapter.sendMethod(element);
      sendMethod : function(element) {
        // ...
      }
    };

Generally the only changes need to be made in the `JSAdapter` js module specifically to implement the `sendRequest` and `sendMethod` functions that are used by all the events to power the UJS functionality.

Once that unobtrusive adapter has been implemented, you can finish by adding the UJS file to the generator in Padrino:

    # padrino-gen/lib/padrino-gen/generators/components/scripts/extcore.rb
    def setup_script
      get('https://github.com/padrino/padrino-static/raw/master/js/jquery.js',
         destination_root("/public/javascripts/jquery.js"))
      get('https://github.com/padrino/padrino-static/raw/master/ujs/jquery-ujs.js',
         destination_root("/public/javascripts/jquery-ujs.js"))
      create_file(destination_root('/public/javascripts/application.js'), 
         "// Put your application scripts here")
    end

and update the tests:

    # padrino-gen/test/test_project_generator.rb
    context "the generator for script component" do
      should "properly generate for jquery" do
        # ...
        assert_match(/Applying.*?jquery.*?script/, buffer)
        assert_file_exists("#{@apptmp}/sample_project/public/javascripts/jquery.js")
        assert_file_exists("#{@apptmp}/sample_project/public/javascripts/jquery-ujs.js")
        assert_file_exists("#{@apptmp}/sample_project/public/javascripts/application.js")
      end
      # ...
    end

 

## Testing Library

Contributing an additional testing library to Padrino is actually quite straightforward. For this guide, let’s assume we want to add `shoulda` as a testing component integrated into Padrino. First, let’s add `shoulda` to the project generator’s available components in [padrino-gen/generators/project.rb](http://github.com/padrino/padrino-framework/blob/master/padrino-gen/lib/padrino-gen/generators/project.rb#L29):

    # padrino-gen/lib/padrino-gen/generators/project.rb
    component_option :test, "testing framework", :choices => [:rspec, :shoulda]

Next, let’s define the actual integration of the testing library into the generator in [padrino-gen/generators/components/tests/shoulda\_test.rb](http://github.com/padrino/padrino-framework/blob/master/padrino-gen/lib/padrino-gen/generators/components/tests/shoulda_test.rb):

    # padrino-gen/lib/padrino-gen/generators/components/tests/shoulda_test.rb
    SHOULDA_SETUP = (<<-TEST).gsub(/^ {10}/, '')
    PADRINO_ENV = 'test' unless defined?(PADRINO_ENV)
    require File.expand_path(File.dirname(__FILE__) + "/../config/boot")

    class Test::Unit::TestCase
      include Rack::Test::Methods

      def app
        CLASS_NAME
      end
    end
    TEST

    def setup_test
      require_dependencies 'shoulda', :group => 'test'
      insert_test_suite_setup SHOULDA_SETUP
      create_file destination_root("test/test.rake"), SHOULDA_RAKE
    end

    # Generates a controller test given the controllers name
    def generate_controller_test(name)
      # ...truncated...
    end

    def generate_model_test(name)
      # ...truncated...
    end

Let’s also add a test to ensure the new testing component generates as expected in [padrino-gen/test/test\_project\_generator.rb](http://github.com/padrino/padrino-framework/blob/master/padrino-gen/test/test_project_generator.rb#L234):

    # padrino-gen/test/test_project_generator.rb
    should "properly generate for shoulda" do
      buffer = silence_logger {@project.start(['sample_project', '--root=/tmp', '--test=shoulda', '--script=none'])}
      assert_match /Applying.*?shoulda.*?test/, buffer
      assert_match_in_file(/gem 'shoulda'/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/Test::Unit::TestCase/, '/tmp/sample_project/test/test_config.rb')
      assert_file_exists('/tmp/sample_project/test/test.rake')
    end

and finally let’s update the README for `padrino-gen` to reflect the new component in [padrino-gen/README.rdoc](http://github.com/padrino/padrino-framework/blob/master/padrino-gen/README.rdoc):

    # padrino-gen/README.rdoc
    test:: rspec (default), bacon, shoulda, cucumber, testspec, riot

 

## Rendering Engine

Contributing a rendering engine to Padrino is actually quite straightforward. For this guide, let’s assume we want to add `haml` as a rendering engine integrated into Padrino. First, let’s add `haml` to the project generator’s available components in [padrino-gen/generators/project.rb](http://github.com/padrino/padrino-framework/blob/master/padrino-gen/lib/padrino-gen/generators/project.rb#L32):

    # padrino-gen/lib/padrino-gen/generators/project.rb
    ccomponent_option :renderer, "template engine", :choices => [:haml, :erb]

Next, let’s define the actual integration of the rendering engine into the generator in [padrino-gen/generators/components/renderers/haml.rb](http://github.com/padrino/padrino-framework/blob/master/padrino-gen/lib/padrino-gen/generators/components/renderers/haml.rb):

    # padrino-gen/lib/padrino-gen/generators/components/renderers/haml.rb
    def setup_renderer
      require_dependencies 'haml'
    end

Let’s also add a test to ensure the new rendering component generates as expected in [padrino-gen/test/test\_project\_generator.rb](http://github.com/padrino/padrino-framework/blob/master/padrino-gen/test/test_project_generator.rb#L161):

    # padrino-gen/test/test_project_generator.rb
    should "properly generate for haml" do
      buffer = silence_logger {@project.start(['sample_project', '--root=/tmp', '--renderer=haml','--script=none'])}
      assert_match /Applying.*?haml.*?renderer/, buffer
      assert_match_in_file(/gem 'haml'/, '/tmp/sample_project/Gemfile')
    end

and finally let’s update the README for `padrino-gen` to reflect the new component in [padrino-gen/README.rdoc](http://github.com/padrino/padrino-framework/blob/master/padrino-gen/README.rdoc):

    # padrino-gen/README.rdoc
    renderer:: erb (default), haml

When adding support for a new rendering engine, you are highly encouraged to also include support for this engine within the `padrino-admin` gem. This admin gem constructs views and forms based on templates provided for each supported renderer.

When adding a new renderer, be sure to add templates for each of the necessary admin views. The necessary templates and structure can be found in the [padrino-admin/generators/templates/haml](http://github.com/padrino/padrino-framework/tree/master/padrino-admin/lib/padrino-admin/generators/templates/haml/) views folder. Be sure to implement all of these if you want the integrated rendering engine to work with the admin dashboard.

Finally, let’s update the `padrino-admin` README file at [padrino-admin/README.rdoc](http://github.com/padrino/padrino-framework/blob/master/padrino-admin/README.rdoc) to reflect our newly support component:

    # padrino-admin/README.rdoc
    Template Agnostic:: Erb and Haml Renderer

This completes the full integration of a rendering engine into Padrino. Once all of this has been finished in your github fork, send us a pull request and assuming you followed these instructions properly and the engine actually works when generated, we will include the component into the next Padrino version crediting you for the contribution!

 

## Mocking Library

Contributing an additional mocking library to Padrino is actually quite straightforward. For this guide, let’s assume we want to add `mocha` as a mocking component integrated into Padrino. First, let’s add `mocha` to the project generator’s available components in [padrino-gen/generators/project.rb](http://github.com/padrino/padrino-framework/blob/master/padrino-gen/lib/padrino-gen/generators/project.rb#L30):

    # padrino-gen/lib/padrino-gen/generators/project.rb
    component_option :mock, "mocking library", :choices => [:mocha, :rr]

Next, let’s define the actual integration of the mocking library into the generator in [padrino-gen/generators/components/mocks/mocha.rb](http://github.com/padrino/padrino-framework/blob/master/padrino-gen/lib/padrino-gen/generators/components/mocks/mocha.rb):

    # padrino-gen/lib/padrino-gen/generators/components/mocks/mocha.rb
    def setup_mock
     require_dependencies 'mocha', :group => 'test'
     insert_mocking_include "Mocha::API"
    end

Let’s also add a test to ensure the new mocking component generates as expected in [padrino-gen/test/test\_project\_generator.rb](http://github.com/padrino/padrino-framework/blob/master/padrino-gen/test/test_project_generator.rb#L93):

    # padrino-gen/test/test_project_generator.rb
    should "properly generate for mocha and rspec" do
      buffer = silence_logger {@project.start(['sample_project', '--root=/tmp', '--mock=mocha'])}
      assert_match /Applying.*?mocha.*?mock/, buffer
      assert_match_in_file(/gem 'mocha'/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/conf.mock_with :mocha/m, '/tmp/sample_project/spec/spec_helper.rb')
    end

and finally let’s update the README for `padrino-gen` to reflect the new component in [padrino-gen/README.rdoc](http://github.com/padrino/padrino-framework/blob/master/padrino-gen/README.rdoc):

    # padrino-gen/README.rdoc
    mock:: none (default), mocha, rr

This completes the full integration of a mocking library into Padrino. Once all of this has been finished in your github fork, send us a pull request and assuming you followed these instructions properly and the library actually works when generated, we will include the component into the next Padrino version crediting you for the contribution!

 

## Stylesheet Engine

Contributing an additional stylesheet engine to Padrino is actually quite straightforward. For this guide, let’s assume we want to add `less` as a stylesheet engine component integrated into Padrino. First, let’s add `less` to the project generator’s available components in [padrino-gen/generators/project.rb](http://github.com/padrino/padrino-framework/blob/master/padrino-gen/lib/padrino-gen/generators/project.rb#L33):

    # padrino-gen/lib/padrino-gen/generators/project.rb
    component_option :stylesheet, "stylesheet engine", :choices => [:sass, :less]

Next, let’s define the actual integration of the stylesheet engine into the generator in [padrino-gen/generators/components/stylesheets/less.rb](http://github.com/padrino/padrino-framework/blob/master/padrino-gen/lib/padrino-gen/generators/components/stylesheets/less.rb):

    # padrino-gen/lib/padrino-gen/generators/components/stylesheets/less.rb
    LESS_INIT = (<<-LESS).gsub(/^ {6}/, '')
    require 'rack/less'
    Rack::Less.configure do |config|
      config.compress = true
    end
    app.use Rack::Less, :root => app.root, :source  => 'stylesheets/',
                        :public    => 'public/', :hosted_at => '/stylesheets'
    LESS

    def setup_stylesheet
      require_dependencies 'less', 'rack-less'
      initializer :less, LESS_INIT
      empty_directory destination_root('/app/stylesheets')
    end

Let’s also add a test to ensure the new stylesheet engine component generates as expected in [padrino-gen/test/test\_project\_generator.rb](http://github.com/padrino/padrino-framework/blob/master/padrino-gen/test/test_project_generator.rb#L278):

    # padrino-gen/test/test_project_generator.rb
    should "properly generate for less" do
      buffer = silence_logger { @project.start(['sample_project', '--root=/tmp', '--stylesheet=less']) }
      assert_match_in_file(/gem 'less'/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/gem 'rack-less'/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/module LessInitializer.*Rack::Less/m, '/tmp/sample_project/lib/less_init.rb')
      assert_match_in_file(/register LessInitializer/m, '/tmp/sample_project/app/app.rb')
      assert_dir_exists('/tmp/sample_project/app/stylesheets')
    end

and finally let’s update the README for `padrino-gen` to reflect the new component in [padrino-gen/README.rdoc](http://github.com/padrino/padrino-framework/blob/master/padrino-gen/README.rdoc):

    # padrino-gen/README.rdoc
    stylesheet:: sass (default), less

This completes the full integration of a stylesheet engine into Padrino. Once all of this has been finished in your github fork, send us a pull request and assuming you followed these instructions properly and the engine actually works when generated, we will include the component into the next Padrino version crediting you for the contribution!

 

## Locale Translations

In addition to components, we also encourage developers to send us their locale translations allowing Padrino to support a wide variety of different languages.

In order to add locale translations, simply port the following yml files to your favorite language. For this example, let’s port over Padrino to Russian. The following yml files must be translated:

-   [padrino-core/locale/ru.yml](http://github.com/padrino/padrino-framework/blob/master/padrino-core/lib/padrino-core/locale/ru.yml)
-   [padrino-helpers/locale/ru.yml](http://github.com/padrino/padrino-framework/blob/master/padrino-helpers/lib/padrino-helpers/locale/ru.yml)
-   [padrino-admin/locale/admin/ru.yml](http://github.com/padrino/padrino-framework/blob/master/padrino-admin/lib/padrino-admin/locale/admin/ru.yml)
-   [padrino-admin/locale/orm/ru.yml](http://github.com/padrino/padrino-framework/blob/master/padrino-admin/lib/padrino-admin/locale/orm/ru.yml)

This completes the full integration of a new locale into Padrino. Once all of this has been finished in your github fork, send us a pull request and assuming you followed these instructions properly and the language has proper translations, we will include the locale into the next Padrino version crediting you for the contribution!

An example of the [actual commit](http://github.com/padrino/padrino-framework/commit/64465d1835cf32996bc36bb14ed9fd1c21e3cd76) of the Russian locale translations are a great example of how to contribute to Padrino.