module Padrino
  module Admin
    class AccessControlError < StandardError #:nodoc:
    end

    ##
    # This module give to a padrino application an access control functionality like:
    #   
    #   class EcommerceDemo < Padrino::Application
    #     enable :authentication
    #     set :login_page, "/login" # or your login page
    #     enable :store_location # if you want know what is the page that need authentication
    # 
    #     access_control.roles_for :any do
    #       role.require_login "/cart"
    #       role.require_login "/account"
    #       role.allow "/account/create"
    #     end
    #   end
    # 
    # In the EcommerceDemo, we +only+ require logins for all paths that start with "/cart" like:
    # 
    #   - "/cart/add"
    #   - "/cart/empty"
    #   - "/cart/checkout"
    # 
    # same thing for "/account" so we require a login for:
    # 
    #   - "/account"
    #   - "/account/edit"
    #   - "/account/update"
    # 
    # but if we call "/account/create" we don't need to be logged in our site for do that.
    # In EcommerceDemo example we set +redirect_back_or_default+ so if a +unlogged+ 
    # user try to access "/account/edit" will be redirected to "/login" when login is done will be 
    # redirected to "/account/edit".
    # 
    # If we need something more complex aka roles/permissions we can do that in the same simple way
    # 
    #   class AdminDemo < Padrino::Application
    #     enable :authentication
    #     set :login_page, "/sessions/new" # or your page
    #     
    #     access_control.roles_for :any do |role|
    #       role.allow "/sessions"
    #     end
    #   
    #     access_control.roles_for :admin do |role, account|
    #       role.allow "/"
    #       role.deny  "/posts"
    #     end
    #     
    #     access_control.roles_for :editor do |role, account|
    #       role.allow "/posts"
    #     end
    #   end
    # 
    #   If a user logged with role admin can:
    #   
    #   - Access to all paths that start with "/session" like "/sessions/{new,create}"
    #   - Access to any page except those that start with "/posts"
    # 
    #   If a user logged with role editor can:
    # 
    #   - Access to all paths that start with "/session" like "/sessions/{new,create}"
    #   - Access +only+ to paths that start with "/posts" like "/post/{new,edit,destroy}"
    # 
    # Finally we have another good fatures, the possibility in the same time we build role build also +tree+.
    # Figure this scenario: in my admin every account need their own menu, so an Account with role editor have
    # a menu different than an Account with role admin.
    # 
    # So:
    # 
    #   class AdminDemo < Padrino::Application
    #     enable :authentication
    #     set :redirect_to_default, "/" # or your page
    #     
    #     access_control.roles_for :any do |role|
    #       role.allow "/sessions"
    #     end
    #     
    #     access_control.roles_for :admin do |role, current_account|
    #       
    #       role.project_module :settings do |project|
    #         project.menu :accounts, "/accounts" do |accounts|
    #           accounts.add :new, "/accounts/new" do |account|
    #             account.add :administrator, "/account/new/?role=administrator"               
    #             account.add :editor,        "/account/new/?role=editor"
    #           end
    #         end
    #         project.menu :spam_rules, "/manage_spam"
    #       end
    #       
    #       role.project_module :categories do |project|
    #         current_account.categories.each do |category|
    #           project.menu category.name, "/categories/#{category.id}.js"
    #         end
    #       end
    #     end
    #     
    #     access_control.roles_for :editor do |role, current_account|
    #       
    #       role.project_module :posts do |posts|
    #         post.menu :list, "/posts"
    #         post.menu :new,  "/posts/new"
    #       end
    #     end
    # 
    # In this example when we build our menu tree we are also defining roles so:
    # 
    # An Admin Account have access to:
    # 
    # - All paths that start with "/sessions"
    # - All paths that start with "/accounts"
    # - All paths that start with "/manage_spam"
    # 
    # An Editor Account have access to:
    # 
    # - All paths that start with "/posts"
    # 
    # Remember that you always deny a specific actions or allow globally others.
    # 
    # Remember that when you define role_for :a_role, you have also access to the Model Account.
    #
    module AccessControl

      ##
      # Method used by Padrino::Application when we register the extension
      # 
      def self.registered(app)
        app.set :session_id, "_padrino_#{File.basename(Padrino.root)}_#{app.app_name}".to_sym
        app.helpers Padrino::Admin::Helpers
        app.before { login_required }
        app.use Padrino::Admin::Middleware::FlashMiddleware, app.session_id  # make sure that is the same of session_name in helpers
        Padrino::Admin::Orm.extend_account!
      end

      class Base
        class << self
          attr_reader :roles

          def inherited(base) #:nodoc:
            base.class_eval("@@cache={}; @authorizations=[]; @roles=[]; @mappers=[]")
            base.send(:cattr_reader, :cache)
            super
          end

          ##
          # We map project modules for a given role or roles
          # 
          def roles_for(*roles, &block)
            raise Padrino::Admin::AccessControlError, "Role #{role} must be present and must be a symbol!" if roles.any? { |r| !r.kind_of?(Symbol) } || roles.empty?
            raise Padrino::Admin::AccessControlError, "You can't merge :any with other roles"              if roles.size > 1 && roles.any? { |r| r == :any }

            if roles == [:any]
              @authorizations << Authorization.new(&block)
            else
              raise Padrino::Admin::AccessControlError, "For use custom roles you need to define an Account Class" unless defined?(Account)
              @roles.concat(roles)
              @mappers << Proc.new { |account| Mapper.new(account, *roles, &block) }
            end
          end

          ##
          # Returns (allowed && denied paths).
          # If an account given we also give allowed & denied paths for their role.
          # 
          def auths(account=nil)
            if account
              cache[account.id] ||= Auths.new(@authorizations, @mappers, account)
            else
              cache[:any] ||= Auths.new(@authorizations)
            end
          end
        end
      end # Base

      class Auths #:nodoc:
        attr_reader :allowed, :denied, :project_modules

        def initialize(authorizations, mappers=nil, account=nil) #:nodoc:
          @allowed, @denied = [], []
          unless authorizations.empty?
            @allowed = authorizations.collect(&:allowed).flatten
            @denied  = authorizations.collect(&:denied).flatten
          end
          if mappers && !mappers.empty?
            maps = mappers.collect { |m|  m.call(account) }.reject { |m| !m.allowed? }
            @allowed.concat(maps.collect(&:allowed).flatten)
            @denied.concat(maps.collect(&:denied).flatten)
            @project_modules = maps.collect(&:project_modules).flatten.uniq
          else
            @project_modules = []
          end
          @allowed.uniq!
          @denied.uniq!
        end

        ##
        # Return true if the requested path (like request.path_info) is allowed.
        # 
        def can?(request_path)
          return true if @allowed.empty?
          request_path = "/" if request_path.blank?
          @allowed.any? { |path| request_path =~ /^#{path}/ } && !cannot?(request_path)
        end

        ##
        # Return true if the requested path (like request.path_info) is +not+ allowed.
        # 
        def cannot?(request_path)
          return false if @denied.empty?
          request_path = "/" if request_path.blank?
          @denied.any? { |path| request_path =~ /^#{path}/ }
        end
      end # Auths

      class Authorization
        attr_reader :allowed, :denied

        def initialize(&block) #:nodoc:
          @allowed = []
          @denied  = []
          yield self
        end

        ##
        # Allow a specified path
        # 
        def allow(path)
          @allowed << path unless @allowed.include?(path)
        end

        ##
        # Deny a specified path
        # 
        def require_login(path)
          @denied << path unless @denied.include?(path)
        end
        alias :deny :require_login
      end # Authorization

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

        ##
        # Create a new project module
        # 
        def project_module(name, path=nil, &block)
          @project_modules << ProjectModule.new(name, path, &block)
        end

        ##
        # Globally allow an paths for the current role
        # 
        def allow(path)
          @allowed << path unless @allowed.include?(path)
        end

        ##
        # Globally deny an pathsfor the current role
        # 
        def deny(path)
          @denied << path unless @allowed.include?(path)
        end

        ##
        # Return true if role is included in given roles
        # 
        def allowed?
          @roles.any? { |r| r == @account.role.to_s.downcase.to_sym }
        end

        ##
        # Return allowed paths
        # 
        def allowed
          @project_modules.each { |pm| @allowed.concat(pm.allowed)  }
          @allowed.uniq
        end
      end # Mapper

      class ProjectModule
        attr_reader :name, :menus, :path

        def initialize(name, path=nil, options={}, &block) #:nodoc:
          @name     = name
          @options  = options
          @allowed  = []
          @menus    = []
          @path     = path
          @allowed << path if path
          yield self if block_given?
        end

        ##
        # Build a new menu and automaitcally add the action on the allowed actions.
        # 
        def menu(name, path=nil, options={}, &block)
          @menus << Menu.new(name, path, options, &block)
        end

        ##
        # Return allowed controllers
        # 
        def allowed
          @menus.each { |m| @allowed.concat(m.allowed) }
          @allowed.uniq
        end

        ##
        # Return the original name or try to translate or humanize the symbol
        # 
        def human_name
          @name.is_a?(Symbol) ? I18n.t("admin.menus.#{@name}", :default => @name.to_s.humanize) : @name
        end

        ##
        # Return symbol for the given project module
        # 
        def uid
          @name.to_s.downcase.gsub(/[^a-z0-9]+/, '').gsub(/-+$/, '').gsub(/^-+$/, '').to_sym
        end

        ##
        # Return ExtJs Config for this project module
        # 
        def config
          options = @options.merge(:text => human_name)
          options.merge!(:menu => @menus.collect(&:config)) if @menus.size > 0
          options.merge!(:handler => Padrino::Admin::Config::Variable.new("function(){ Admin.app.load('#{path}') }")) if @path
          options
        end
      end # ProjectModule

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

        ##
        # Add a new submenu to the menu
        # 
        def add(name, path=nil, options={}, &block)
          @items << Menu.new(name, path, options, &block)
        end

        ##
        # Return allowed controllers
        # 
        def allowed
          @items.each { |i| @allowed.concat(i.allowed) }
          @allowed.uniq
        end

        ##
        # Return the original name or try to translate or humanize the symbol
        # 
        def human_name
          @name.is_a?(Symbol) ? I18n.t("admin.menus.#{@name}", :default => @name.to_s.humanize) : @name
        end

        ##
        # Return a unique id for the given project module
        # 
        def uid
          @name.to_s.downcase.gsub(/[^a-z0-9]+/, '').gsub(/-+$/, '').gsub(/^-+$/, '').to_sym
        end

        ##
        # Return ExtJs Config for this menu
        # 
        def config
          if @path.blank? && @items.empty?
            options = human_name
          else
            options = @options.merge(:text => human_name)
            options.merge!(:menu => @items.collect(&:config)) if @items.size > 0
            options.merge!(:handler => "function(){ Admin.app.load('#{path}') }".to_l) if @path
          end
          options
        end
      end # Menu
    end # AccessControl
  end # Admin
end # Padrino