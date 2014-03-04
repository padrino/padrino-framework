module Padrino
  module Generators
    ##
    # Generator action definitions for the admin panel.
    #
    module Admin
      ##
      # Important tasks for setting up or configuring the admin application.
      #
      module Actions
        ##
        # Tell us which orm we are using.
        #
        def orm
          fetch_component_choice(:orm).to_sym rescue :activerecord
        end
        alias :adapter :orm

        ##
        # Tell us which rendering engine you are using.
        #
        def ext
          fetch_component_choice(:admin_renderer).to_sym rescue :haml
        end

        ##
        # Tell us for now which orm we support
        #
        def supported_orm
          [:minirecord, :datamapper, :activerecord, :mongomapper, :mongoid, :couchrest, :sequel, :ohm, :dynamoid]
        end

        ##
        # Tell us for now which rendering engine we support.
        #
        def supported_ext
          [:haml, :slim, :erb]
        end

        ##
        # Add access_control permission in our app.rb.
        #
        def add_project_module(controller)
          permission = "      role.project_module :#{controller}, '/#{controller}'\n"
          inject_into_file destination_root(@admin_path+'/app.rb'),  permission, :after => "access_control.roles_for :admin do |role|\n"
        end

        ##
        # Remove from access_control permissions.
        #
        def remove_project_module(controller)
          path = destination_root(@admin_path+'/app.rb')
          say_status :replace, @admin_path+'/app.rb', :red
          content = File.binread(path)
          content.gsub!(/^\s+role\.project_module :#{controller}, '\/#{controller}'\n/, '')
          File.open(path, 'wb') { |f| f.write content }
        end

        ##
        # Returns the app_name for the application at root.
        #
        # @param [String] app
        #   folder name of application.
        #
        # @return [String] module name for application.
        #
        # @example
        #   fetch_app_name('subapp')
        #
        # @api public
        def fetch_app_name(app='app')
          app_path = destination_root(app, 'app.rb')
          @app_name ||= File.read(app_path).scan(/module\s(.*?)\n/).flatten[0]
        end
      end
    end
  end
end
