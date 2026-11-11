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
      #   post :update, params: [:name, :email]
      #   post :update, params: [:name, { id: Integer }]
      #   post :update, params: [{ name: proc { |v| v.reverse } }]
      #   post :update, params: [:name, { parent: [:name, :position] }]
      #   post :update, params: [{ tags: [] }]             # an array of plain values
      #   post :update, params: [{ users: [:name, :age] }] # an array or collection of hashes
      #   post :update, params: false
      #   post :update, params: true
      # @example
      #   params :name, :email, password: proc { |v| v.reverse }
      #   post :update
      # @example
      #   App.controller :accounts, params: [:name, :position] do
      #     post :create
      #     post :update, with: [:id], params: [:name, :position, :addition]
      #     get :show, with: :id, params: false
      #     get :search, params: true
      #
      #     # A controller block nested in this one uses the same list unless it
      #     # gives its own +params:+.
      #   end
      #
      # A route's or controller's +params:+ list keeps the parameters the
      # route's +with:+ and +parent:+ options capture when each is a string.
      # Other captures, such as those in a +map:+ or the format, are kept only
      # when listed.
      #
      def params(*allowed_params)
        allowed_params = prepare_allowed_params(allowed_params)
        condition do
          @original_params = params
          @params = Utils.deep_dup(params)
          filter_params!(@params, allowed_params)
        end
      end

      private

      def prepare_allowed_params(allowed_params)
        param_filter = {}
        allowed_params.each do |key, value|
          if key.is_a?(Hash) && !value
            param_filter.update(prepare_allowed_params(key))
          elsif value.is_a?(Hash) || value.is_a?(Array)
            param_filter[key.to_s] = prepare_allowed_params(value)
          else
            param_filter[key.to_s] = value == false ? false : (value || true)
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
      #   scalar classes are: Integer (empty string is cast to nil) and String.
      #   A value of another shape than its key allows (a hash or an array for
      #   Integer or String, a string for a nested list) is dropped. A proc is
      #   called with the value as sent, an array or a hash included.
      #
      # @example
      #   filter_params!( { 'a' => '1', 'b' => 'abc', 'd' => 'drop' },
      #                   { 'a' => Integer, 'b' => true } )
      #   # => { 'a' => 1, 'b' => 'abc' }
      #   filter_params!( { 'id' => '', 'child' => { 'name' => 'manny' } },
      #                   { 'id' => Integer, 'child' => { 'name' => proc{ |v| v.camelize } } } )
      #   # => { 'id' => nil, 'child' => { 'name' => 'Manny' } }
      #   filter_params!( { 'a' => ['1', '2', '3'] },
      #                   { 'a' => true } )
      #   # => { 'a' => ['1', '2', '3'] }
      #   filter_params!( { 'a' => ['1', '2'], 'b' => ['1', '2'] },
      #                   { 'a' => {}, 'b' => Integer } )
      #   # => { 'a' => ['1', '2'] }
      #   filter_params!( { 'people' => [{ 'name' => 'manny', 'age' => '50' }] },
      #                   { 'people' => { 'name' => true } } )
      #   # => { 'people' => [{ 'name' => 'manny' }] }
      #   filter_params!( { 'persons' => { 'p-1' => { 'name' => 'manny', 'age' => '50' }, 'p-2' => { 'name' => 'richard', 'age' => '50' } } },
      #                   { 'persons' => { 'name' => true } } )
      #   # => { 'persons' => { 'p-1' => { 'name' => 'manny' }, 'p-2' => { 'name' => 'richard' } } }
      #
      def filter_params!(params, allowed_params)
        params.each do |key, value|
          type = allowed_params[key]
          if type.is_a?(Hash) && value.is_a?(Hash)
            if key == Inflections.pluralize(key) && value.values.first.is_a?(Hash)
              value.keep_if { |_, array_value| array_value.is_a?(Hash) }
              value.each do |array_index, array_value|
                value[array_index] = filter_params!(array_value, type)
              end
            else
              params[key] = filter_params!(value, type)
            end
          elsif type.is_a?(Hash) && value.is_a?(Array)
            params[key] = filter_array_param(value, type)
          elsif type == Integer && (value.nil? || value.is_a?(String) || value.is_a?(Integer))
            params[key] = value.to_s.empty? ? nil : value.to_i
          elsif type.is_a?(Proc)
            params[key] = type.call(value)
          elsif type == String
            params.delete(key) unless value.is_a?(String)
          elsif type != true
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

      private

      # An empty list (+names: []+) takes an array of plain values; a list of
      # keys takes an array of hashes, each filtered by it.
      def filter_array_param(values, allowed_params)
        if allowed_params.empty?
          values.reject { |value| value.is_a?(Hash) || value.is_a?(Array) }
        else
          values.filter_map { |value| filter_params!(value, allowed_params) if value.is_a?(Hash) }
        end
      end
    end
  end
end
