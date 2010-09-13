module Padrino
  module Cache
    module Store
      class Memory
        def initialize(size = 5000)
          @size, @entries, @index = size, [], {}
        end

        def get(key)
          if @index.key?(key) and value = @index[key]
            expires_in, body = value
            if expires_in == -1 or Time.new.to_i < expires_in
              set(key, body, :expires_in => expires_in)
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
          delete(key) if @index.key?(key)
          if opts && opts[:expires_in]
            expires_in = opts[:expires_in].to_i
            expires_in = Time.new.to_i + expires_in if expires_in < EXPIRES_EDGE
          else
            expires_in = -1
          end
          @entries.push(key)
          @index[key] = [expires_in, value]

          while @entries.size > @size
            delete(@entries.shift)
          end
        end

        def delete(key)
          @index.delete(key)
        end

        def flush
          @index = Hash.new
        end
      end # Memory
    end # Store
  end # Cache
end # Padrino
