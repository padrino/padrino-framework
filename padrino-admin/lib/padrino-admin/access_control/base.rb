module Padrino
  module AccessControl
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
    #       role.project_module :categories do |project|
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
    class Base
      @@cache = {}
      cattr_accessor :cache
      
      class << self
        
        # We map project modules for a given role or roles
        def roles_for(*roles, &block)
          roles.each { |role| raise AccessControlError, "Role #{role} must be a symbol!" unless role.is_a?(Symbol)  }
          @mappers ||= []
          @roles   ||= []
          @roles.concat(roles)
          @mappers << Proc.new { |account| Mapper.new(account, *roles, &block) }
        end
        
        # Returns all roles
        def roles
          @roles.nil? ? [] : @roles.collect(&:to_s)
        end

        # Returns maps (allowed && denied actions) for the given account
        def maps_for(account)
          @@cache[account.id] ||= @mappers.collect { |m| m.call(account) }.
                                           reject  { |m| !m.allowed? }
          @@cache[account.id]
        end
      end
    end
    
    class Mapper
      attr_reader :project_modules, :roles
      
      def initialize(account, *roles, &block)#:nodoc:
        @project_modules = []
        @allowed         = []
        @denied          = []
        @roles           = roles
        @account_id      = account.is_a?(Account) ? account.id : account
        yield(self, Account.find(@account_id)) rescue yield(self)
      end
      
      # Create a new project module
      def project_module(name, controller=nil, &block)
        @project_modules << ProjectModule.new(name, controller, &block)
      end
      
      # Globally allow an action / controller for the current role
      def allow(path)
        @allowed << path
      end
      
      # Globally deny an action / controllerfor the current role
      def deny(path)
        @denied << path
      end
      
      # Return true if current_account role is included in given roles
      def allowed?
        @roles.any? { |r| r.to_s.downcase == Account.find(@account_id).role.downcase }
      end
      
      # Return denied actions/controllers
      def denied
        @denied.uniq
      end
    end
    
    class ProjectModule
      attr_reader :name, :menus, :url
      
      def initialize(name, path=nil, options={}, &block)#:nodoc:
        @name = name
        @options = options
        @allowed = []
        @menus   = []
        if path
          @url      = path
          @allowed << path
        end
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
      
      # Return a unique id for the given project module
      def uid
        @name.to_s.downcase.gsub(/[^a-z0-9]+/, '').gsub(/-+$/, '').gsub(/^-+$/, '')
      end
      
      # Return ExtJs Config for this project module
      def config
        options = @options.merge(:text => human_name)
        options.merge!(:menu => @menus.collect(&:config)) if @menus.size > 0
        options.merge!(:handler =>  "function(){ Admin.app.load('#{url_for(@url.merge(:only_path => true))}') }".to_l) if @url
        options
      end
    end
    
    class Menu
      attr_reader :name, :options, :items
      
      def initialize(name, path=nil, options={}, &block)#:nodoc:
        @name    = name
        @url     = path
        @options = options
        @allowed = []
        @items   = []        
        @allowed << { :controller => recognize_path(path)[:controller] } if @url
        yield self if block_given?
      end
      
      # Return the url of this menu
      def url
        @url.is_a?(Hash) ? url_for(@url.merge(:only_path => true)) : @url
      end
      
      # Add a new submenu to the menu
      def add(name, path=nil, options={}, &block)
        @items << Menu.new(name, path, options, &block)
      end
      
      # Return allowed controllers
      def allowed
        @items.each { |i| @allowed.concat i.allowed }
        @allowed.uniq
      end
      
      # Return the original name or try to translate or humanize the symbol
      def human_name
        @name.is_a?(Symbol) ? I18n.t("admin.menus.#{@name}", :default => @name.to_s.humanize) : @name
      end
      
      # Return a unique id for the given project module
      def uid
        @name.to_s.downcase.gsub(/[^a-z0-9]+/, '').gsub(/-+$/, '').gsub(/^-+$/, '')
      end
      
      # Return ExtJs Config for this menu
      def config
        if @url.blank? && @items.empty?
          options = human_name
        else
          options = @options.merge(:text => human_name)
          options.merge!(:menu => @items.collect(&:config)) if @items.size > 0
          options.merge!(:handler => "function(){ Admin.app.load('#{url}') }".to_l) if !@url.blank?
        end
        options
      end
    end
    
    class AccessControlError < StandardError#:nodoc:
    end
  end
end