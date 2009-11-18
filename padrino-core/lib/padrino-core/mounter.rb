module Padrino
  # Represents a particular mounted padrino application
  # Stores the name of the application (app folder name) and url mount path
  # @example Mounter.new("blog_app").to("/blog")
  # @example Mounter.new("blog_app", :app_file => "/path/to/root/app.rb").to("/blog")
  # @example Mounter.new("blog_app", :app_class => "Blog").to("/blog")
  class Mounter
    attr_accessor :name, :uri_root, :app_file, :klass
    def initialize(name, options={})
      @name     = name
      @klass    = options[:app_class] || name.classify
      @app_file = options[:app_file]  || Padrino.mounted_root(name, 'app.rb')
    end

    # registers the mounted application to Padrino
    def to(mount_url)
      @uri_root = mount_url
      Padrino.mounted_apps << self
    end
  end

  class << self
    # Returns the root to the mounted apps base directory
    def mounted_root(*args)
      File.join(Padrino.root, "apps", *args)
    end

    # Returns the mounted padrino applications (MountedApp objects)
    def mounted_apps
      @mounted_apps ||= []
    end

    # Mounts a new sub-application onto Padrino
    # @example Padrino.mount("blog_app").to("/blog")
    # @example Padrino.mount("blog_app", :app_file => "/path/to/root/app.rb").to("/blog")
    def mount(name, options={})
      Mounter.new(name, options)
    end
  end
end
