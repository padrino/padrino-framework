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
        # Tell us which orm we are using
        #
        def orm
          fetch_component_choice(:orm).to_sym rescue :activerecord
        end
        alias :adapter :orm

        ##
        # Tell us which rendering engine you are using
        #
        def ext
          fetch_component_choice(:admin_renderer).to_sym rescue :haml
        end

        ##
        # Tell us for now wich orm we support
        #
        def supported_orm
          [:datamapper, :activerecord, :mongomapper, :mongoid, :couchrest, :sequel]
        end

        ##
        # Tell us for now wich rendering engine we support
        #
        def supported_ext
          [:haml, :erb, :slim]
        end

        ##
        # Add access_control permission in our app.rb
        #
        def add_project_module(controller)
          permission = "    role.project_module :#{controller}, \"/#{controller}\"\n"
          inject_into_file destination_root("/admin/app.rb"),  permission, :after => "access_control.roles_for :admin do |role|\n"
        end

        ##
        # Remove from access_control permissions
        #
        def remove_project_module(controller)
          path = destination_root("/admin/app.rb")
          say_status :replace, "admin/app.rb", :red
          content = File.binread(path)
          content.gsub!(/^\s+role\.project_module :#{controller}, "\/#{controller}"\n/, '')
          File.open(path, 'wb') { |f| f.write content }
        end
      end # Actions
    end # Admin
  end # Generators
end # Padrino
