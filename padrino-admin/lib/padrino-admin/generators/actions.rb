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
          [:datamapper, :activerecord]
        end

        ##
        # Add access_control permission in our app.rb
        # 
        def add_project_module(controller)
          permission = indent(6, "role.project_module :#{controller}, \"/#{controller}\"\n")
          inject_into_file destination_root("/admin/app.rb"),  permission, :after => "access_control.roles_for :admin do |role, account|\n"
        end

        ##
        # Indent a content/string for the given spaces
        # 
        def indent(count, content)
          indent = ' ' * count
          content.lines.map { |line| line != "\n" ? indent+line : "\n" }.join
        end
      end # Actions
    end # Admin
  end # Generators
end # Padrino