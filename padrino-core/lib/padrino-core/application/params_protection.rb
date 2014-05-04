module Padrino
  ##
  # Padrino application module providing means for mass-assignment protection.
  #
  module ParamsProtection
    class << self
      def registered(app)
        included(app)
      end

      def included(base)
        base.send(:include, InstanceMethods)
        base.extend(ClassMethods)
      end
    end

    module ClassMethods
      ##
      # Implements filtering of url query params. Can prevent mass-assignment.
      #
      # @example
      #   post :update, :allow => [:name, :email]
      #   post :update, :allow => [:name, :id => Integer]
      #   post :update, :allow => [:name => proc{ |v| v.reverse }]
      #   post :update, :allow => [:name, :parent => [:name, :position]]
      # @example
      #   allow :name, :email, :password => prox{ |v| v.reverse }
      #   post :update        
      #
      def allow(*allowed_params)
        allowed_params = prepare_allowed_params(allowed_params)
        condition do
          filter_params!(params, allowed_params)
        end
      end

      private

      def prepare_allowed_params(allowed_params)
        param_filter = {}
        allowed_params.each do |key,value|
          case
          when key.kind_of?(Hash) && !value
            param_filter.update(prepare_allowed_params(key))
          when value.kind_of?(Hash) || value.kind_of?(Array)
            param_filter[key.to_s] = prepare_allowed_params(value)
          else
            param_filter[key.to_s] = value || true
          end
        end
        param_filter.freeze
      end
    end

    module InstanceMethods
      ##
      # Filters a hash of parameters leaving only allowed ones and possibly
      # typecasting and processing the others.
      #
      # @param [Hash] params
      #   Parameters to filter.
      #   Warning: this hash will be changed by deleting or replacing its values.
      # @param [Hash] allowed_params
      #   A hash of allowed keys and value classes or processing procs. Supported
      #   scalar classes are: Integer (empty string is casted to nil).
      #
      # @example
      #   filter_params!( { "a" => "1", "b" => "abc", "d" => "drop" },
      #                   { "a" => Integer, "b" => true } )
      #   # => { "a" => 1, "b" => "abc" }
      #   filter_params!( { "id" => "", "child" => { "name" => "manny" } },
      #                   { "id" => Integer, "child" => { "name" => proc{ |v| v.camelize } } } )
      #   # => { "id" => nil, "child" => { "name" => "Manny" } }
      #
      def filter_params!(params, allowed_params)
        params.each do |key,value|
          type = allowed_params[key]
          case
          when type.kind_of?(Hash)
            params[key] = filter_params!(value, type)
          when type == Integer
            params[key] = value.empty? ? nil : value.to_i
          when type.kind_of?(Proc)
            params[key] = type.call(value)
          when type == true
          else
            params.delete(key)
          end
        end
      end
    end
  end
end
