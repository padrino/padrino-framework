module Padrino
  module Generators
    module Actions
      # For access control permissions
      def access_control(name)
        (<<-RUBY)
      role.project_module :#{name} do |project|
        project.menu :list, "/admin/#{name}.js"
        project.menu :new,  "/admin/#{name}/new"
      end

        RUBY
      end
    end
  end
end