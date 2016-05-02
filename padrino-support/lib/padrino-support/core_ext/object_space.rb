module ObjectSpace
  class << self
    ##
    # Returns all the classes in the object space.
    # Optionally, a block can be passed, for example the following code
    # would return the classes that start with the character "A":
    #
    #  ObjectSpace.classes do |klass|
    #    if klass.to_s[0] == "A"
    #      klass
    #    end
    #  end
    #
    def classes(&block)
      warn 'Warning! ObjectSpace.classes will be removed in Padrino 0.14'
      require 'padrino-core/reloader'
      Padrino::Reloader::Storage.send(:object_classes, &block)
    end

    ##
    # Returns a list of existing classes that are not included in "snapshot"
    # This method is useful to get the list of new classes that were loaded
    # after an event like requiring a file.
    # Usage:
    #
    #   snapshot = ObjectSpace.classes
    #   # require a file
    #   ObjectSpace.new_classes(snapshot)
    #
    def new_classes(snapshot)
      warn 'Warning! ObjectSpace.new_classes will be removed in Padrino 0.14'
      require 'padrino-core/reloader'
      Padrino::Reloader::Storage.send(:new_classes, snapshot)
    end
  end
end
