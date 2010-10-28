module Padrino
  ##
  # Represents a particular mounted padrino application
  # Stores the name of the application (app folder name) and url mount path
  #
  # ==== Examples
  #
  #   Mounter.new("blog_app", :app_class => "Blog").to("/blog")
  #   Mounter.new("blog_app", :app_file => "/path/to/blog/app.rb").to("/blog")
  #
  class Mounter
    class MounterException < RuntimeError #:nodoc:
    end

    attr_accessor :name, :uri_root, :app_file, :app_class, :app_root, :app_obj, :app_host

    def initialize(name, options={})
      @name      = name.to_s.underscore
      @app_class = options[:app_class] || @name.camelize
      @app_file  = options[:app_file]  || locate_app_file
      @app_obj   = options[:app_obj]   || app_constant || locate_app_object
      ensure_app_file! || ensure_app_object!
      @app_root  = options[:app_root]  || File.dirname(@app_file)
      @uri_root  = "/"
    end

    ##
    # Registers the mounted application onto Padrino
    #
    # ==== Examples
    #
    #   Mounter.new("blog_app").to("/blog")
    #
    def to(mount_url)
      @uri_root  = mount_url
      Padrino.insert_mounted_app(self)
      self
    end

    ##
    # Registers the mounted application onto Padrino for the given host
    #
    # ==== Examples
    #
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
    # Maps Padrino application onto a Padrino::Router
    # For use in constructing a Rack application
    #
    #   @app.map_onto(router)
    #
    def map_onto(router)
      app_data, app_obj = self, @app_obj
      app_obj.set :uri_root, app_data.uri_root
      app_obj.set :app_name, app_data.name
      app_obj.set :app_file, app_data.app_file unless ::File.exist?(app_obj.app_file)
      app_obj.set :root,     app_data.app_root unless app_data.app_root.blank?
      app_obj.set :public,   Padrino.root('public', app_data.uri_root) unless File.exists?(app_obj.public)
      app_obj.set :static,   File.exist?(app_obj.public) if app_obj.nil?
      app_obj.setup_application! # We need to initialize here the app.
      router.map(:to => app_obj, :path => app_data.uri_root, :host => app_data.app_host)
    end

    ###
    # Returns the route objects for the mounted application
    #
    def routes
      app_obj.routes
    end

    ###
    # Returns the basic route information for each named route
    #
    #
    def named_routes
      app_obj.routes.map { |route|
        name_array     = "(#{route.named.to_s.split("_").map { |piece| %Q[:#{piece}] }.join(", ")})"
        request_method = route.as_options[:conditions][:request_method][0]
        full_path = File.join(self.uri_root, route.path)
        next if route.named.blank? || request_method == 'HEAD'
        OpenStruct.new(:verb => request_method, :identifier => route.named, :name => name_array, :path => full_path)
      }.compact
    end

    ##
    # Makes two Mounters equal if they have the same name and uri_root
    #
    def ==(other)
      other.is_a?(Mounter) && self.app_class == other.app_class && self.uri_root == other.uri_root
    end
    
    protected
    
    ##
    # Locates and requires the file to load the app constant
    #
    def locate_app_object
      @_app_object ||= begin
        ensure_app_file!
        Padrino.require_dependencies(app_file)
        app_constant
      end
    end

    ##
    # Returns the determined location of the mounted application main file
    #
    def locate_app_file
      candidates  = []
      candidates << app_constant.app_file if app_constant.respond_to?(:app_file) && File.exist?(app_constant.app_file.to_s)
      candidates << Padrino.first_caller if File.identical?(Padrino.first_caller.to_s, Padrino.called_from.to_s)
      candidates << Padrino.mounted_root(name, "app.rb")
      candidates << Padrino.root("app", "app.rb")
      candidates.find { |candidate| File.exist?(candidate) }
    end
    
    ##
    # Returns the class object for the app if defined, nil otherwise
    #
    def app_constant
      app_class.constantize if Object.const_defined?(app_class)
    end
    
    ###
    # Raises an exception unless app_file is located properly
    #
    def ensure_app_file!
      message = "Unable to locate source file for app '#{name}', try with :app_file => '/path/app.rb'"
      raise MounterException, message unless @app_file
    end
    
    ###
    # Raises an exception unless app_obj is defined properly
    #
    def ensure_app_object!
      message = "Unable to locate app for '#{name}', try with :app_class => 'MyAppClass'"
      raise MounterException, message unless @app_obj
    end
  end

  class << self
    attr_writer :mounted_root # Set root directory where padrino searches mounted apps

    ##
    # Returns the root to the mounted apps base directory
    #
    def mounted_root(*args)
      Padrino.root(@mounted_root ||= "", *args)
    end

    ##
    # Returns the mounted padrino applications (MountedApp objects)
    #
    def mounted_apps
      @mounted_apps ||= []
    end

    ##
    # Inserts a Mounter object into the mounted applications (avoids duplicates)
    #
    def insert_mounted_app(mounter)
      Padrino.mounted_apps.push(mounter) unless Padrino.mounted_apps.include?(mounter)
    end

    ##
    # Mounts the core application onto Padrino project with given app settings (file, class, root)
    #
    # ==== Examples
    #
    #   Padrino.mount_core("Blog")
    #   Padrino.mount_core(:app_file => "/path/to/file", :app_class => "Blog")
    #
    def mount_core(*args)
      # TODO Remove this in 0.9.14 or pre 1.0
      warn "DEPRECATION! #{Padrino.first_caller}: Padrino.mount_core has been deprecated.\nUse Padrino.mount('AppName').to('/') instead"
      options = args.extract_options!
      app_class = args.size > 0 ? args.first.to_s.camelize : nil
      options.reverse_merge!(:app_class => app_class)
      mount("core", options).to("/")
    end

    ##
    # Mounts a new sub-application onto Padrino project
    #
    #   Padrino.mount("blog_app").to("/blog")
    #
    def mount(name, options={})
      Mounter.new(name, options)
    end
  end # Mounter
end # Padrino