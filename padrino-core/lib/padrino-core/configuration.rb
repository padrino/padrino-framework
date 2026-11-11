module Padrino
  ##
  # Padrino simple configuration module
  #
  module Configuration
    ##
    # Holds the values set through Padrino.config. Any name can be set and read
    # like an attribute, and a name that was never set reads as nil.
    #
    # A name that is also a method of this object (such as +class+, +hash+ or
    # +to_h+) still calls that method; read and write it with +[]+ and +[]=+.
    # +logger+ and +display+ read and write values like any other name.
    #
    # Example:
    #
    #   Padrino.config.value1 = 42
    #   Padrino.config.value1           # => 42
    #   Padrino.config[:value1]         # => 42
    #   Padrino.config['value1'] = 43
    #   Padrino.config.missing          # => nil
    #   Padrino.config.to_h             # => { value1: 43 }
    #
    class Store
      def initialize
        @table = {}
      end

      ##
      # A copy (dup or clone) gets its own values, so setting one leaves the original alone.
      #
      def initialize_copy(other)
        super
        @table = @table.dup
      end

      ##
      # A clone of a frozen Store stays frozen, unless cloned with freeze: false.
      #
      def initialize_clone(other, freeze: nil)
        super(other)
        @table.freeze if freeze.nil? ? other.frozen? : freeze
      end

      ##
      # Returns the value set for +name+ (a String or Symbol), or nil.
      #
      def [](name)
        @table[name.to_sym]
      end

      ##
      # Sets the value for +name+ (a String or Symbol).
      #
      def []=(name, value)
        @table[name.to_sym] = value
      end

      ##
      # Returns the value for +name+, then digs into it with +names+, as Hash#dig does.
      #
      def dig(name, *names)
        @table.dig(name.to_sym, *names)
      end

      ##
      # Removes +name+ and returns its value. When +name+ isn't set, returns the
      # block's value if a block is given and raises NameError otherwise.
      #
      def delete_field(name)
        key = name.to_sym
        @table.delete(key) do
          return yield if block_given?

          raise NameError.new("no field '#{key}' in #{self}", key)
        end
      end

      ##
      # Returns a new Hash of the values, with Symbol keys. A block maps each
      # pair, as Hash#to_h does.
      #
      def to_h(&block)
        block ? @table.to_h(&block) : @table.dup
      end

      ##
      # Yields each name and value, or returns an Enumerator without a block.
      #
      def each_pair(&block)
        return to_enum(:each_pair) { @table.size } unless block

        @table.each_pair(&block)
        self
      end

      ##
      # True when +other+ is a Store holding the same values.
      #
      def ==(other)
        other.is_a?(Store) && @table == other.table
      end

      ##
      # Like ==, but compares the values with eql?, as Hash keys do.
      #
      def eql?(other)
        other.is_a?(Store) && @table.eql?(other.table)
      end

      def hash
        @table.hash
      end

      ##
      # Freezes the values too, so setting one raises FrozenError.
      #
      def freeze
        @table.freeze
        super
      end

      def inspect
        "#<#{self.class}#{@table.map { |key, value| " #{key}=#{value.inspect}" }.join(',')}>"
      end
      alias to_s inspect

      protected

      attr_reader :table

      private

      # Kernel#logger (from padrino-core) and Kernel#display would otherwise hide these
      # names; as private methods here, a call with a receiver reaches method_missing.
      def logger
        @table[:logger]
      end

      def display
        @table[:display]
      end

      def method_missing(name, *args)
        writer = name.end_with?('=')
        if writer && args.size == 1
          self[name[0...-1]] = args.first
        elsif !writer && args.empty?
          @table[name]
        else
          super
        end
      end

      def respond_to_missing?(name, include_private = false)
        @table.key?(name.to_s.chomp('=').to_sym) || super
      end
    end

    ##
    # Returns the configuration structure allowing to get and set it's values.
    # Padrino.config is a {Store}: set any value on it and read it back.
    #
    # Example:
    #
    #   Padrino.config.value1 = 42
    #   exit if Padrino.config.exiting
    #
    def config
      @config ||= Store.new
    end

    ##
    # Allows to configure different environments differently. Requires a block.
    #
    # Example:
    #
    #   Padrino.configure :development do |config|
    #     config.value2 = 'only development'
    #   end
    #   Padrino.configure :development, :production do |config|
    #     config.value2 = 'both development and production'
    #   end
    #   Padrino.configure do |config|
    #     config.value2 = 'any environment'
    #   end
    #
    def configure(*environments)
      yield(config) if environments.empty? || environments.include?(Padrino.env)
    end
  end
end
