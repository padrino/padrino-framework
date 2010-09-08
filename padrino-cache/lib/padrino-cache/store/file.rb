module Padrino
  module Cache
    module Store
      class File
        def initialize(root)
          @root = root
        end

        def get(key)
          init
          if ::File.exist?(path_for_key(key))
            contents = ::File.read(path_for_key(key))
            expires_in, body = contents.split("\n", 2)
            expires_in = expires_in.to_i
            if expires_in == -1 or Time.new.to_i < expires_in
              body
            else
              delete(key)
              nil
            end
          else
            nil
          end
        end

        def set(key, value, opts = nil)
          init
          if opts && opts[:expires_in]
            expires_in = opts[:expires_in].to_i
            expires_in = Time.new.to_i + expires_in if expires_in < EXPIRES_EDGE
          else
            expires_in = -1
          end
          ::File.open(path_for_key(key), 'w') { |f| f << expires_in.to_s << "\n" << value.to_s } if value
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