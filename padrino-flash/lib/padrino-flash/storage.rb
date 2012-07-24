# encoding: UTF-8
module Padrino
  module Flash
    class Storage
      include Enumerable

      attr_reader :now
      attr_reader :next

      # @private
      def initialize(session)
        @now  = session || {}
        @next = {}
      end

      # @since 0.1.0
      # @api public
      def [](type)
        @now[type]
      end

      # @since 0.1.0
      # @api public
      def []=(type, message)
        @next[type] = message
      end

      # @since 0.1.0
      # @api public
      def delete(type)
        @now.delete(type)
        self
      end

      # @since 0.1.0
      # @api public
      def keys
        @now.keys
      end

      # @since 0.1.0
      # @api public
      def key?(type)
        @now.key?(type)
      end

      # @since 0.1.0
      # @api public
      def each(&block)
        @now.each(&block)
      end

      # @since 0.1.0
      # @api public
      def replace(hash)
        @now.replace(hash)
        self
      end

      # @since 0.1.0
      # @api public
      def update(hash)
        @now.update(hash)
        self
      end
      alias_method :merge!, :update

      # @since 0.1.0
      # @api public
      def sweep
        @now.replace(@next)
        @next = {}
        self
      end

      # @since 0.1.0
      # @api public
      def keep(key = nil)
        if key
          @next[key] = @now[key]
        else
          @next.merge!(@now)
        end
      end

      # @since 0.1.0
      # @api public
      def discard(key = nil)
        if key
          @next.delete(key)
        else
          @next = {}
        end
      end

      # @since 0.1.0
      # @api public
      def clear
        @now.clear
      end

      # @since 0.1.0
      # @api public
      def empty?
        @now.empty?
      end

      # @since 0.1.0
      # @api public
      def to_hash
        @now.dup
      end

      # @since 0.1.0
      # @api public
      def to_s
        @now.to_s
      end

      # @since 0.1.0
      # @api public
      def error=(message)
        self[:error] = message
      end

      # @since 0.1.0
      # @api public
      def error
        self[:error]
      end

      # @since 0.1.0
      # @api public
      def notice=(message)
        self[:notice] = message
      end

      # @since 0.1.0
      # @api public
      def notice
        self[:notice]
      end

      # @since 0.1.0
      # @api public
      def success=(message)
        self[:success] = message
      end

      # @since 0.1.0
      # @api public
      def success
        self[:success]
      end
    end # Storage
  end # Flash
end # Padrino