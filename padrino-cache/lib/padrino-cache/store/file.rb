module Padrino
  module Cache
    module Store
      class File
        def initialize(root)
          @root = root
        end

        def get(key)
          init
          ::File.exist?(path_for_key(key)) ? ::File.read(path_for_key(key)) : nil
        end

        def set(key, value)
          init
          ::File.open(path_for_key(key), 'w') { |f| f << value.to_s } if value
        end

        def delete(key)
          init
          FileUtils.rm_rf(path_for_key(key))
        end

        private
        def path_for_key(key)
          ::File.join(@root, Rack::Utils.escape(key.to_s))
        end
        
        def init
          unless @init
            FileUtils.rm_rf(@root)
            FileUtils.mkdir_p(@root)
            @init = true
          end
        end
      end
    end
  end
end