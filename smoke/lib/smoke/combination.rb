require 'yaml'

module Smoke
  # One named set of generator choices from combinations.yml.
  class Combination
    COMPONENT_TYPES = %w[orm renderer test mock script stylesheet].freeze
    COMPONENTS_DIR = CHECKOUT.join('padrino-gen/lib/padrino-gen/generators/components')
    SQL_ORMS = %w[activerecord sequel].freeze
    ADMIN_RENDERERS = %w[erb haml slim].freeze
    ADAPTERS = %w[sqlite postgres mysql2 trilogy].freeze
    SERVERS = %w[webrick puma thin falcon].freeze
    SHAPES = %w[tiny lean api].freeze

    attr_reader :name, :orm, :adapter, :renderer, :test, :mock, :script, :stylesheet, :server,
                :ruby, :add_component, :allowed_failure, :shape

    def self.load(path = ROOT.join('combinations.yml'))
      YAML.safe_load(File.read(path)).map { |attrs| new(attrs) }
    end

    def self.find(name, combos = load)
      combos.find { |c| c.name == name } ||
        raise(ArgumentError, "no smoke combination #{name.inspect}; choose one of: #{combos.map(&:name).join(', ')}")
    end

    # Every component, adapter, server and project shape, and every orm x renderer and orm x test pair, must appear.
    def self.coverage_gaps(combos)
      gaps = []
      COMPONENT_TYPES.each do |type|
        choices = Dir[COMPONENTS_DIR.join("#{type}s", '*.rb').to_s].map { |f| File.basename(f, '.rb') }
        choices << 'none' if type == 'orm'
        (choices - combos.map { |c| c.public_send(type) }).each { |missing| gaps << "#{type}: #{missing}" }
      end
      (ADAPTERS - combos.map(&:adapter)).each { |missing| gaps << "adapter: #{missing}" }
      (SERVERS - combos.map(&:server)).each { |missing| gaps << "server: #{missing}" }
      (SHAPES - combos.map(&:shape)).each { |missing| gaps << "shape: #{missing}" }
      orms = combos.map(&:orm).uniq
      %w[renderer test].each do |type|
        values = combos.map { |c| c.public_send(type) }.uniq
        orms.product(values).each do |orm, value|
          next if combos.any? { |c| c.orm == orm && c.public_send(type) == value }
          gaps << "orm x #{type}: #{orm} x #{value}"
        end
      end
      gaps
    end

    def initialize(attrs)
      @name = attrs.fetch('name')
      COMPONENT_TYPES.each { |type| instance_variable_set("@#{type}", attrs.fetch(type, 'none')) }
      @adapter = SQL_ORMS.include?(@orm) ? attrs.fetch('adapter', 'sqlite') : nil
      @server = attrs.fetch('server', 'webrick')
      @ruby = attrs.fetch('ruby', '4.0').to_s
      @no_db_clients = attrs.fetch('no_db_clients', false)
      @add_component = attrs.fetch('add_component', {})
      @allowed_failure = attrs['allowed_failure']
      @shape = attrs['shape']
    end

    def admin?
      orm != 'none' && ADMIN_RENDERERS.include?(renderer) && !lean? && !api?
    end

    def lean?
      shape == 'lean'
    end

    def api?
      shape == 'api'
    end

    def no_db_clients?
      @no_db_clients
    end

    def vite?
      script == 'vite'
    end

    def sql?
      SQL_ORMS.include?(orm)
    end

    def generator_flags
      flags = component_flags + ["--server=#{server}"]
      shape ? flags + ["--#{shape}"] : flags
    end

    # Flags `padrino g component` takes: it has no --server.
    def component_flags
      flags = ["--orm=#{orm}"]
      flags << "--adapter=#{adapter}" if adapter
      flags + (COMPONENT_TYPES - ['orm']).map { |type| "--#{type}=#{public_send(type)}" }
    end
  end
end
