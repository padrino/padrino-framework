require 'padrino-core/mounter/application_extension'

module Padrino
  ##
  # Represents a particular mounted Padrino application.
  # Stores the name of the application (app folder name) and url mount path.
  #
  # @example
  #   Mounter.new("blog_app", :app_class => "Blog").to("/blog")
  #   Mounter.new("blog_app", :app_file => "/path/to/blog/app.rb").to("/blog")
  #
  class Mounter
    DEFAULT_CASCADE = [404, 405]
    class MounterException < RuntimeError
    end

    attr_accessor :name, :uri_root, :app_file, :app_class, :app_root, :app_obj, :app_host, :cascade

    ##
    # @param [String, Padrino::Application] name
    #   The app name or the {Padrino::Application} class.
    #
    # @param [Hash] options
    # @option options [Symbol] :app_class (Detected from name)
    # @option options [Symbol] :app_file (Automatically detected)
    # @option options [Symbol] :app_obj (Detected)
    # @option options [Symbol] :app_root (Directory of :app_file)
    # @option options [Symbol] :gem The gem to load the app from (Detected from name)
    #
    def initialize(name, options={})
      @name      = name.to_s
      @app_class = options[:app_class] || Inflections.camelize(@name)
      @gem       = options[:gem]       || Inflections.underscore(@app_class.split("::").first)
      @app_file  = options[:app_file]  || locate_app_file
      @app_obj   = options[:app_obj]   || app_constant || locate_app_object
      ensure_app_file! || ensure_app_object!
      unless padrino_application?
        @app_obj.extend ApplicationExtension
        @app_obj.mounter_options = options
      end
      @app_root  = options[:app_root]  || (@app_obj.respond_to?(:root) && @app_obj.root || File.dirname(@app_file))
      @uri_root  = "/"
      @cascade   = options[:cascade] ? true == options[:cascade] ? DEFAULT_CASCADE.dup : Array(options[:cascade]) : []
      Padrino::Reloader.exclude_constants << @app_class
    end

    def padrino_application?
      @app_obj.ancestors.include?(Padrino::Application)
    rescue NameError
      false
    end

    ##
    # Registers the mounted application onto Padrino.
    #
    # @param [String] mount_url
    #   Path where we mount the app.
    #
    # @example
    #   Mounter.new("blog_app").to("/blog")
    #
    def to(mount_url)
      @uri_root  = mount_url
      Padrino.insert_mounted_app(self)
      self
    end

    ##
    # Registers the mounted application onto Padrino for the given host.
    #
    # @param [String] mount_host
    #   Host name.
    #
    # @example
    #   Mounter.new("blog_app").to("/blog").host("blog.padrino.org")
    #   Mounter.new("blog_app").host("blog.padrino.org")
    #   Mounter.new("catch_all").host(/.*\.padrino.org/)
    #
    def host(mount_host)
      @app_host = mount_host
      Padrino.insert_mounted_app(self)
      self
    end

    ##
    # Maps Padrino application onto a Padrino::Router.
    # For use in constructing a Rack application.
    #
    # @param [Padrino::Router]
    #
    # @return [Padrino::Router]
    #
    # @example
    #   @app.map_onto(router)
    #
    def map_onto(router)
      app_data = self
      app_obj = @app_obj

      uri_root             = app_data.uri_root
      public_folder_exists = File.exist?(app_obj.public_folder)

      if padrino_application?
        app_obj.set :uri_root,       uri_root
        app_obj.set :app_name,       app_obj.app_name.to_s
        app_obj.set :root,           app_data.app_root
        app_obj.set :public_folder,  Padrino.root('public', uri_root) unless public_folder_exists
        app_obj.set :static,         public_folder_exists
        app_obj.set :cascade,        app_data.cascade
      else
        app_obj.cascade       = app_data.cascade
        app_obj.uri_root      = uri_root
        app_obj.public_folder = Padrino.root('public', uri_root) unless public_folder_exists
      end
      app_obj.setup_application! # Initializes the app here with above settings.
      router.map(:to => app_obj, :path => uri_root, :host => app_data.app_host)
    end

    ###
    # Returns the route objects for the mounted application.
    #
    def routes
      app_obj.routes
    end

    ###
    # Returns the basic route information for each named route.
    #
    # @return [Array]
    #   Array of routes.
    #
    def named_routes
      return [] unless app_obj.respond_to?(:routes)

      app_obj.routes.map { |route|
        request_method = route.request_methods.first
        next if !route.name || request_method == 'HEAD'
        route_name = route.name.to_s
        route_name =
          if route.controller
            route_name.split(" ", 2).map{|name| ":#{name}" }.join(", ")
          else
            ":#{route_name}"
          end
        name_array = "(#{route_name})"
        original_path = route.original_path.is_a?(Regexp) ? route.original_path.inspect : route.original_path
        full_path = File.join(uri_root, original_path)
        OpenStruct.new(:verb => request_method, :identifier => route.name, :name => name_array, :path => full_path)
      }.compact
    end

    ##
    # Makes two Mounters equal if they have the same name and uri_root.
    #
    # @param [Padrino::Mounter] other
    #
    def ==(other)
      other.is_a?(Mounter) && self.app_class == other.app_class && self.uri_root == other.uri_root
    end

    ##
    # @return [Padrino::Application]
    #  the class object for the app if defined, nil otherwise.
    #
    def app_constant
      klass = Object
      for piece in app_class.split("::")
        piece = piece.to_sym
        if klass.const_defined?(piece, false)
          klass = klass.const_get(piece)
        else
          return
        end
      end
      klass
    end

    protected
    ##
    # Locates and requires the file to load the app constant.
    #
    def locate_app_object
      @_app_object ||= begin
        ensure_app_file!
        Padrino.require_dependencies(app_file)
        app_constant
      end
    end

    ##
    # Returns the determined location of the mounted application main file.
    #
    def locate_app_file
      app_const = app_constant

      candidates  = []
      candidates << app_const.app_file if app_const.respond_to?(:app_file)
      candidates << Padrino.first_caller if File.identical?(Padrino.first_caller.to_s, Padrino.called_from.to_s)
      candidates << Padrino.mounted_root(name.downcase, "app.rb")
      simple_name = name.split("::").last.downcase
      mod_name = name.split("::")[0..-2].join("::")
      Padrino.modules.each do |mod|
        if mod.name == mod_name
          candidates << mod.root(simple_name, "app.rb")
        end
      end
      candidates << Padrino.root("app", "app.rb")
      candidates.find { |candidate| File.exist?(candidate) }
    end

    ###
    # Raises an exception unless app_file is located properly.
    #
    def ensure_app_file!
      message = "Unable to locate source file for app '#{app_class}', try with :app_file => '/path/app.rb'"
      raise MounterException, message unless @app_file
    end

    ###
    # Raises an exception unless app_obj is defined properly.
    #
    def ensure_app_object!
      message = "Unable to locate app for '#{app_class}', try with :app_class => 'MyAppClass'"
      raise MounterException, message unless @app_obj
    end
  end

  class << self
    attr_writer :mounted_root # Set root directory where padrino searches mounted apps

    ##
    # @param [Array] args
    #
    # @return [String]
    #   the root to the mounted apps base directory.
    #
    def mounted_root(*args)
      Padrino.root(@mounted_root ||= "", *args)
    end

    ##
    # @return [Array]
    #   the mounted padrino applications (MountedApp objects)
    #
    def mounted_apps
      @mounted_apps ||= []
    end

    ##
    # Inserts a Mounter object into the mounted applications (avoids duplicates).
    #
    # @param [Padrino::Mounter] mounter
    #
    def insert_mounted_app(mounter)
      Padrino.mounted_apps.push(mounter) unless Padrino.mounted_apps.include?(mounter)
    end

    ##
    # Mounts a new sub-application onto Padrino project.
    #
    # @see Padrino::Mounter#new
    #
    # @example
    #   Padrino.mount("blog_app").to("/blog")
    #
    def mount(name, options={})
      Mounter.new(name, options)
    end
  end
end
