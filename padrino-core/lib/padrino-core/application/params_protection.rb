require 'active_support/core_ext/object/deep_dup'

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
      #   post :update, :params => [:name, :email]
      #   post :update, :params => [:name, :id => Integer]
      #   post :update, :params => [:name => proc{ |v| v.reverse }]
      #   post :update, :params => [:name, :parent => [:name, :position]]
      #   post :update, :params => false
      #   post :update, :params => true
      # @example
      #   params :name, :email, :password => prox{ |v| v.reverse }
      #   post :update        
      #
      def params(*allowed_params)
        allowed_params = prepare_allowed_params(allowed_params)
        condition do
          @original_params = params.deep_dup
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
      #   scalar classes are: Integer (empty string is cast to nil).
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

      ##
      # Returns the original unfiltered query parameters hash.
      #
      def original_params
        @original_params || params
      end
    end
  end
end
