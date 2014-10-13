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
    def classes
      rs = Set.new

      ObjectSpace.each_object(Class).each do |klass|
        if block_given?
          if r = yield(klass)
            # add the returned value if the block returns something
            rs << r
          end
        else
          rs << klass
        end
      end

      rs
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
      self.classes do |klass|
        if !snapshot.include?(klass)
          klass
        end
      end
    end
  end
end
