autoload :AutoloadLazy, File.expand_path('lazy.rb', __dir__)

class AutoloadUser
  include AutoloadConcern
end
