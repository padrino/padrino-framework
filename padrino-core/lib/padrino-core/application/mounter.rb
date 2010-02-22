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
    attr_accessor :name, :uri_root, :app_file, :app_class, :app_root, :app_obj

    def initialize(name, options={})
      @name      = name.downcase
      @app_class = options[:app_class] || name.classify
      @app_file  = options[:app_file]  || locate_app_file
      @app_root  = options[:app_root]  || File.dirname(@app_file)
      @app_obj   = self.app_object
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
    # Maps Padrino application onto a Rack::Builder
    # For use in constructing a Rack application
    # 
    #   @app.map_onto(@builder)
    # 
    def map_onto(builder)
      app_data, app_obj = self, @app_obj
      builder.map self.uri_root do
        app_obj.set :uri_root, app_data.uri_root
        app_obj.set :app_name, app_data.name
        app_obj.set :app_file, app_data.app_file unless ::File.exist?(app_obj.app_file)
        app_obj.set :root,     app_data.app_root unless app_data.app_root.blank?
        app_obj.setup_application! # We need to initialize here the app.
        run app_obj
      end
    end

    ##
    # Return the class for the app
    # 
    def app_object
      app_class.constantize rescue Padrino.require_dependency(app_file)
      app_class.constantize
    end

    ##
    # Returns the determined location of the mounted application main file
    # 
    def locate_app_file
      callers_are_identical = File.identical?(Padrino.first_caller.to_s, Padrino.called_from.to_s)
      callers_are_identical ? Padrino.first_caller : Padrino.mounted_root(name, "app.rb")
    end

    ##
    # Makes two Mounters equal if they have the same name and uri_root
    # 
    def ==(other)
      other.is_a?(Mounter) && self.name == other.name && self.uri_root == other.uri_root
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
      return false if Padrino.mounted_apps.include?(mounter)
      Padrino.mounted_apps << mounter
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
      options = args.extract_options!
      app_class = args.size > 0 ? args.first.to_s.camelize : nil
      options.reverse_merge!(:app_class => app_class, :app_file => Padrino.root("app", "app.rb"))
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
