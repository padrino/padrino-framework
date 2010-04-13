class Admin < Padrino::Application
  configure do
    ##
    # Application-specific configuration options
    #
    # set :raise_errors, true     # Show exceptions (default for development)
    # set :public, "foo/bar"      # Location for static assets (default root/public)
    # set :sessions, true         # Disabled by default
    # set :reload, false          # Reload application files (default in development)
    # set :default_builder, "foo" # Set a custom form builder (default 'StandardFormBuilder')
    # set :locale_path, "bar"     # Set path for I18n translations (default your_app/locales)
    # disable :padrino_helpers    # Disables padrino markup helpers (enabled by default if present)
    # disable :padrino_mailer     # Disables padrino mailer (enabled by default if present)
    # disable :flash              # Disables rack-flash (enabled by default)
    # enable  :authentication     # Enable padrino-admin authentication (disabled by default)
    # layout  :my_layout          # Layout can be in views/layouts/foo.ext or views/foo.ext (default :application)
    #
    enable  :authentication
    disable :store_location
    set :login_page, "/admin/sessions/new"

    access_control.roles_for :any do |role|
      role.protect "/"
      role.allow "/sessions"
    end

    access_control.roles_for :admin do |role|
    end

  end
end