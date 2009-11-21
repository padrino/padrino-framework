module Padrino
  # Represents a particular mounted padrino application
  # Stores the name of the application (app folder name) and url mount path
  # @example Mounter.new("blog_app", :app_class => "Blog").to("/blog")
  # @example Mounter.new("blog_app", :app_file => "/path/to/blog/app.rb").to("/blog")
  class Mounter
    attr_accessor :name, :uri_root, :app_file, :app_class, :app_root
    def initialize(name, options={})
      @name      = name.downcase
      @app_class = options[:app_class] || name.classify
      @app_file  = options[:app_file]  || locate_app_file
      @app_root  = options[:app_root]
    end

    # Registers the mounted application onto Padrino
    # @example Mounter.new("blog_app").to("/blog")
    def to(mount_url)
      @uri_root = mount_url
      Padrino.mounted_apps << self
    end

    # Maps Padrino application onto a Rack::Builder
    # For use in constructing a Rack application
    # @example @app.map_onto(@builder)
    def map_onto(builder)
      self.app_class.constantize rescue require(self.app_file)
      app_data, app_class = self, self.app_class.constantize
      builder.map self.uri_root do
        app_class.set :uri_root, app_data.uri_root
        app_class.set :app_file, app_data.app_file
        app_class.set :app_name, app_data.name
        app_class.set :root,     app_data.app_root if app_data.app_root
        run app_class
      end
    end

    # Returns the determined location of the mounted application main file
    def locate_app_file
      callers_are_identical = File.identical?(Padrino.first_caller, Padrino.called_from)
      callers_are_identical ? Padrino.first_caller : Padrino.mounted_root(name, "app.rb")
    end
  end

  class << self
    attr_writer :mounted_root # Set root directory where padrino searches mounted apps

    # Returns the root to the mounted apps base directory
    def mounted_root(*args)
      File.join(Padrino.root, @mounted_root ||= "apps", *args)
    end

    # Returns the mounted padrino applications (MountedApp objects)
    def mounted_apps
      @mounted_apps ||= []
    end

    # Mounts the core application onto Padrino project with given app settings (file, class, root)
    # @example Padrino.mount_core("Blog")
    # @example Padrino.mount_core(:app_file => "/path/to/file", :app_class => "Blog")
    def mount_core(*args)
      options = args.extract_options!
      app_class = args.size > 0 ? args.first.to_s.camelize : nil
      options.reverse_merge!(:app_class => app_class, :app_file => Padrino.root('app/app.rb'), :app_root => Padrino.root)
      mount("core", options).to("/")
    end

    # Mounts a new sub-application onto Padrino project
    # @example Padrino.mount("blog_app").to("/blog")
    def mount(name, options={})
      Mounter.new(name, options)
    end
  end
end
