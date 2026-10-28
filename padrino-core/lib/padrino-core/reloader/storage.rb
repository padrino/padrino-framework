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
          constants: object_classes,
          features: old_features = Set.new($LOADED_FEATURES.dup)
        }
        features = file && file[:features] || []
        features.each { |feature| Reloader.safe_load(feature, force: true) }
        Reloader.remove_feature(name) if old_features.include?(name)
      end

      def commit(name)
        entry = {
          constants: new_classes(@old_entries[name][:constants]),
          features: Set.new($LOADED_FEATURES) - @old_entries[name][:features] - [name]
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
          next unless mod.is_a?(::ActiveSupport::Concern) && mod.name
          next unless Object.const_source_location(mod.name)&.first == file
          Reloader.reset_concern(mod) if Object.const_get(mod.name).equal?(mod)
        rescue NameError
          next
        end
      end

      ##
      # Returns all the classes in the object space.
      #
      def object_classes
        klasses = Set.new

        ObjectSpace.each_object(::Class).each do |klass|
          if block_given?
            if (filtered_class = yield(klass))
              klasses << filtered_class
            end
          else
            klasses << klass
          end
        end

        klasses
      end

      ##
      # Returns a list of object space classes that are not included in "snapshot".
      #
      def new_classes(snapshot)
        object_classes do |klass|
          snapshot.include?(klass) ? nil : klass
        end
      end
    end
  end
end
