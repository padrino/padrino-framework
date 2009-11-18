# Initializers can be used to configure information about your padrino app
# The following format is used because initializers are applied as plugins into the application

module ExampleInitializer
  def self.registered(app)
    # Manipulate 'app' here to register components or adjust configuration
    # app.set :example, "foo"
  end
end