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
        file[:constants].each{ |constant| Reloader.remove_constant(constant) }
        file[:features].each{ |feature| Reloader.remove_feature(feature) }
        files.delete(name)
      end

      def prepare(name)
        file = remove(name)
        @old_entries ||= {}
        @old_entries[name] = {
          :constants => object_classes,
          :features  => old_features = Set.new($LOADED_FEATURES.dup)
        }
        features = file && file[:features] || []
        features.each{ |feature| Reloader.safe_load(feature, :force => true) }
        Reloader.remove_feature(name) if old_features.include?(name)
      end

      def commit(name)
        entry = {
          :constants => new_classes(@old_entries[name][:constants]),
          :features  => Set.new($LOADED_FEATURES) - @old_entries[name][:features] - [name]
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
      # Returns all the classes in the object space.
      #
      def object_classes
        klasses = Set.new

        ObjectSpace.each_object(::Class).each do |klass|
          if block_given?
            if filtered_class = yield(klass)
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
