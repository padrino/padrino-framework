module Padrino
  # This Class map and get roles/projects for accounts
  # 
  #   Examples:
  #   
  #     roles_for :administrator do |role, current_account|
  #       role.allow "/admin/base"
  #       role.deny  "/admin/accounts/details"
  #     
  #       role.project_module :administration do |project|
  #         project.menu :general_settings, "/admin/settings" do |submenu|
  #           submenu.add :accounts, "/admin/accounts" do |submenu|
  #             submenu.add :sub_accounts, "/admin/accounts/subaccounts"
  #           end
  #         end
  #       end
  # 
  #       role.project_module :categories do |project, current_account|
  #         current_account.categories.each do |cat|
  #           project.menu cat.name, "/admin/categories/#{cat.id}.js"
  #         end
  #       end
  #     end
  # 
  #   If a user logged with role administrator or that have a project_module administrator can:
  #   
  #   - Access in all actions of "/admin/base" controller
  #   - Denied access to ONLY action <tt>"/admin/accounts/details"</tt>
  #   - Access to a project module called Administration
  #   - Access to all actions of the controller "/admin/settings"
  #   - Access to all actions of the controller "/admin/categories"
  #   - Access to all actions EXCEPT <tt>details</tt> of controller "/admin/accounts"
  #
  module AccessControl

    def self.registered(app)
      app.helpers Padrino::AccessControl::Helpers
    end

    class AccessControlError < StandardError; end

    class Base

      class << self
        
        def inherited(base)
          base.send(:cattr_accessor, :cache)
          base.send(:cache=, {})
          super
        end
        
        # We map project modules for a given role or roles
        def roles_for(*roles, &block)
          raise AccessControlError, "Role #{role} must be present and must be a symbol!" if roles.any? { |r| !r.kind_of?(Symbol) } || roles.empty?
          @mappers ||= []
          @roles   ||= []
          @roles.concat(roles)
          @mappers << Proc.new { |account| Mapper.new(account, *roles, &block) }
        end

        # Returns all roles
        def roles
          @roles.nil? ? [] : @roles
        end

        # Returns maps (allowed && denied actions) for the given account.
        # An account can have access to two or many applications so for build a correct tree of maps it's 
        # also necessary provide <tt>where</tt> options.
        def maps_for(account)
          raise AccessControlError, "You must provide an Account Class!" unless account.is_a?(Account)
          raise AccessControlError, "Account must respond to :role!"     unless account.respond_to?(:role)
          cache[account.id] ||= Maps.new(@mappers, account)
        end
      end
    end

    class Maps
      attr_reader :allowed, :denied, :role, :project_modules

      def initialize(mappers, account) #:nodoc:
        @role            = role
        maps             = mappers.collect { |m|  m.call(account) }.reject { |m| !m.allowed? }
        @allowed         = maps.collect(&:allowed).flatten.uniq
        @denied          = maps.collect(&:denied).flatten.uniq
        @project_modules = maps.collect(&:project_modules).flatten.uniq
      end
    end

    class Mapper
      attr_reader :project_modules, :roles, :denied

      def initialize(account, *roles, &block) #:nodoc:
        @project_modules = []
        @allowed         = []
        @denied          = []
        @roles           = roles
        @account         = account.dup
        yield(self, @account)
      end

      # Create a new project module
      def project_module(name, path=nil, &block)
        @project_modules << ProjectModule.new(name, path, &block)
      end

      # Globally allow an paths for the current role
      def allow(path)
        @allowed << path unless @allowed.include?(path)
      end

      # Globally deny an pathsfor the current role
      def deny(path)
        @denied << path unless @allowed.include?(path)
      end

      # Return true if role is included in given roles
      def allowed?
        @roles.any? { |r| r == @account.role.to_s.downcase.to_sym }
      end

      # Return allowed paths
      def allowed
        @project_modules.each { |pm| @allowed.concat(pm.allowed)  }
        @allowed.uniq
      end
    end

    class ProjectModule
      attr_reader :name, :menus, :path

      def initialize(name, path=nil, options={}, &block)#:nodoc:
        @name     = name
        @options  = options
        @allowed  = []
        @menus    = []
        @path     = path
        @allowed << path if path
        yield self
      end

      # Build a new menu and automaitcally add the action on the allowed actions.
      def menu(name, path=nil, options={}, &block)
        @menus << Menu.new(name, path, options, &block)
      end

      # Return allowed controllers
      def allowed
        @menus.each { |m| @allowed.concat(m.allowed) }
        @allowed.uniq
      end

      # Return the original name or try to translate or humanize the symbol
      def human_name
        @name.is_a?(Symbol) ? I18n.t("admin.menus.#{@name}", :default => @name.to_s.humanize) : @name
      end

      # Return symbol for the given project module
      def uid
        @name.to_s.downcase.gsub(/[^a-z0-9]+/, '').gsub(/-+$/, '').gsub(/^-+$/, '').to_sym
      end

      # Return ExtJs Config for this project module
      def config
        options = @options.merge(:text => human_name)
        options.merge!(:menu => @menus.collect(&:config)) if @menus.size > 0
        options.merge!(:handler => ExtJs::Variable.new("function(){ Admin.app.load('#{path}') }")) if @path
        options
      end
    end

    class Menu
      attr_reader :name, :options, :items, :path

      def initialize(name, path=nil, options={}, &block) #:nodoc:
        @name    = name
        @path    = path
        @options = options
        @allowed = []
        @items   = []        
        @allowed << path if path
        yield self if block_given?
      end

      # Add a new submenu to the menu
      def add(name, path=nil, options={}, &block)
        @items << Menu.new(name, path, options, &block)
      end

      # Return allowed controllers
      def allowed
        @items.each { |i| @allowed.concat(i.allowed) }
        @allowed.uniq
      end

      # Return the original name or try to translate or humanize the symbol
      def human_name
        @name.is_a?(Symbol) ? I18n.t("admin.menus.#{@name}", :default => @name.to_s.humanize) : @name
      end

      # Return a unique id for the given project module
      def uid
        @name.to_s.downcase.gsub(/[^a-z0-9]+/, '').gsub(/-+$/, '').gsub(/^-+$/, '').to_sym
      end

      # Return ExtJs Config for this menu
      def config
        if @path.blank? && @items.empty?
          options = human_name
        else
          options = @options.merge(:text => human_name)
          options.merge!(:menu => @items.collect(&:config)) if @items.size > 0
          options.merge!(:handler => ExtJs::Variable.new("function(){ Admin.app.load('#{path}') }")) if @path
        end
        options
      end
    end
  end
end