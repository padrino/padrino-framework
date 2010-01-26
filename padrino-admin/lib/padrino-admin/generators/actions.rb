module Padrino
  module Generators
    module Actions
      ##
      # Tell us if for our orm we need migrations
      # 
      def skip_migrations
        skip_migration = case orm
          when :activerecord then false
          when :sequel       then false
          else true
        end
      end

      ##
      # Tell us which orm we are using
      # 
      def orm
        fetch_component_choice(:orm).to_sym rescue :datamapper
      end

      ##
      # Tell us for now wich orm we support
      # 
      def supported_orm
        [:datamapper, :activerecord]
      end

      ##
      # Add access_control permission in our app.rb
      # 
      def add_access_control_permission(admin, controller)
        permission = indent(6, access_control(controller))
        if options[:destroy] || !File.read(destination_root("#{admin}/app.rb")).include?(permission)
          inject_into_file destination_root("#{admin}/app.rb"),  permission, :after => "access_control.roles_for :admin do |role, account|\n"
        end
      end

      ##
      # Add a simple permission (allow/deny) to our app.rb
      # 
      def add_permission(admin, permission)
        if options[:destroy] || !File.read(destination_root("#{admin}/app.rb")).include?(permission)
          inject_into_file destination_root("#{admin}/app.rb"),  indent(6, "\n#{permission}\n"), :after => "access_control.roles_for :admin do |role, account|\n"
        end
      end

      ##
      # Indent a content/string for the given spaces
      # 
      def indent(count, content)
        indent = ' ' * count
        content.map { |line| line != "\n" ? indent+line : "\n" }.join
      end

      private
        ##
        # For access control permissions
        # 
        def access_control(controller)
          (<<-RUBY).gsub(/ {12}/,'')
            
            role.project_module :#{controller} do |project|
              project.menu :list, "/admin/#{controller}.js"
              project.menu :new,  "/admin/#{controller}/new"
            end
          RUBY
        end
    end
  end
end