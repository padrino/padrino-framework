module Padrino
  module Reloader
    module Storage
      extend self

      def clear!
        files.each_key do |file|
          remove(file)
          Reloader.remove_feature(file)
        end
        @files = {}
      end

      def remove(name)
        file = files[name] || return
        file[:constants].each { |constant| Reloader.remove_constant(constant) }
        file[:features].each { |feature| Reloader.remove_feature(feature) }
        files.delete(name)
      end

      def prepare(name)
        file = remove(name)
        reset_concerns(name)
        @old_entries ||= {}
        @old_entries[name] = {
          constants: all_classes,
          features: old_features = $LOADED_FEATURES.dup
        }
        features = file && file[:features] || []
        features.each { |feature| Reloader.safe_load(feature, force: true) }
        Reloader.remove_feature(name) if old_features.include?(name)
      end

      def commit(name)
        entry = {
          constants: new_classes(@old_entries[name][:constants]),
          features: Set.new($LOADED_FEATURES - @old_entries[name][:features] - [name])
        }
        files[name] = entry
        @old_entries.delete(name)
      end

      def rollback(name)
        new_classes(@old_entries[name][:constants]).each do |klass|
          loaded_in_name = files.each do |file, data|
            next if file == name
            break if data[:constants].include?(klass)
          end

          Reloader.remove_constant(klass) if loaded_in_name
        end
        @old_entries.delete(name)
      end

      private

      def files
        @files ||= {}
      end

      ##
      # Resets the ActiveSupport::Concern modules first defined in the file. Unlike classes
      # they are kept on reload, so that classes including them keep working and namespaces
      # keep their constants, but their state is reset so the file can define them again.
      #
      def reset_concerns(file)
        return unless defined?(::ActiveSupport::Concern)

        ObjectSpace.each_object(::Module) do |mod|
          # Module#=== doesn't call mod, which can be a DeprecatedConstantProxy that warns on any call.
          next unless ::ActiveSupport::Concern === mod && (name = Reloader.send(:constant_name, mod))
          next unless Object.const_source_location(name)&.first == file
          Reloader.reset_concern(mod) if Object.const_get(name).equal?(mod)
        rescue NameError
          next
        end
      end

      ##
      # Returns the classes in the object space (without singleton classes when it walks the class tree).
      #
      def object_classes(&block)
        klasses = all_classes
        klasses = klasses.filter_map(&block) if block
        Set.new(klasses)
      end

      ##
      # Follows a method past the versions that a library prepended or wrote in Ruby, to the
      # one Class defines natively, or nil when there is none.
      #
      def native_class_method(method)
        method = method.super_method while method && (method.owner != ::Class || method.source_location)
        method
      end

      # Ruby's own Class#subclasses (Ruby 3.1+), so a version that ActiveSupport prepends to hide
      # reloaded classes is bypassed. CRuby only: other engines keep the heap scan until their
      # subclass lists are known to be complete.
      SUBCLASSES = if RUBY_ENGINE == 'ruby' && ::Class.method_defined?(:subclasses)
                     native_class_method(::Class.instance_method(:subclasses))
                   end
      private_constant :SUBCLASSES

      ##
      # Scans the heap for classes, where the class tree walk isn't used.
      #
      def heap_classes
        ObjectSpace.each_object(::Class).to_a
      end

      if SUBCLASSES
        ##
        # Walks the class tree down from BasicObject, which is several times faster than
        # scanning the heap. It leaves out singleton classes, which have no constant to remove.
        #
        def all_classes
          classes = [::BasicObject]
          index = 0
          while (klass = classes[index])
            classes.concat(SUBCLASSES.bind_call(klass))
            index += 1
          end
          classes
        end
      else
        alias all_classes heap_classes
      end

      ##
      # Returns a list of object space classes that are not included in "snapshot".
      #
      def new_classes(snapshot)
        classes = all_classes
        # The snapshot keeps its classes alive, so the same count means no class is new.
        return Set.new if classes.size == snapshot.size
        Set.new(classes - snapshot.to_a)
      end
    end
  end
end
