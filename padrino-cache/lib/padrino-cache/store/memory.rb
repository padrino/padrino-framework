module Padrino
  module Cache
    module Store
      class Memory
        def initialize(size = 5000)
          @entries = []
          @index = {}
        end

        def get(key)
          if @index.key?(key) and value = @entries.at(@index[key])
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
          @entries.push([expires_in, value])
          @index[key] = @entries.size - 1
        end

        def delete(key)
          @entries.delete_at(@index.delete(key)) if @index.key?(key)
        end
      end
    end
  end
end