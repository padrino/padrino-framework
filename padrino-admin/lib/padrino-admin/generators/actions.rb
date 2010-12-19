module Padrino
  module Generators
    module Admin
      module Actions
        ##
        # Tell us which orm we are using
        #
        def orm
          fetch_component_choice(:orm).to_sym rescue :datamapper
        end
        alias :adapter :orm

        ##
        # Tell us for now wich orm we support
        #
        def supported_orm
          [:datamapper, :activerecord, :mongomapper, :mongoid, :couchrest, :sequel]
        end

        ##
        # Add access_control permission in our app.rb
        #
        def add_project_module(controller)
          permission = "      role.project_module :#{controller}, \"/#{controller}\"\n"        
          inject_into_file destination_root("/admin/app.rb"), permission, :after => "access_control.roles_for :admin do |role|\n"
        end
      end # Actions
    end # Admin
  end # Generators
end # Padrino