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
        concerns.clear
      end

      def remove(name)
        file = files[name] || return
        file[:constants].each { |constant| Reloader.remove_constant(constant) }
        file[:features].each { |feature| Reloader.remove_feature(feature) }
        files.delete(name)
      end

      def prepare(name)
        file = remove(name)
        own_concerns = concerns.delete(name) || Set.new
        own_concerns.each { |concern| Reloader.reset_concern(concern) }
        @old_entries ||= {}
        @old_entries[name] = {
          constants: object_classes,
          concerns: object_concerns - own_concerns,
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
        track_concerns(name)
        @old_entries.delete(name)
      end

      def rollback(name)
        track_concerns(name)
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
      # ActiveSupport::Concern modules first defined by each file. Unlike classes they are
      # kept on reload, so that classes including them keep working and namespaces keep
      # their constants, but their state is reset so the file can define them again.
      #
      def concerns
        @concerns ||= {}
      end

      def track_concerns(name)
        new_concerns = object_concerns - @old_entries[name][:concerns]
        concerns[name] = new_concerns unless new_concerns.empty?
      end

      ##
      # Returns the ActiveSupport::Concern modules in the object space that a constant names.
      #
      def object_concerns
        return Set.new unless defined?(::ActiveSupport::Concern)

        ObjectSpace.each_object(::Module).each_with_object(Set.new) do |mod, concerns|
          next unless mod.is_a?(::ActiveSupport::Concern) && mod.name
          concerns << mod if Object.const_get(mod.name).equal?(mod)
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
