require 'rubygems'
require 'yaml'
require 'erb'
require 'json/pure'

module ExtJs

  class ConfigError < RuntimeError; end

  class Variable < String
    yaml_as "tag:yaml.org,2002:js"

    def to_json(*a)
      self
    end
  end

  class Config < Hash
    def initialize(data)
      @data   = data
      parsed  = parse(@data)
      super
      replace parsed
    end

    def self.load_file(path, binding=nil)
      self.load(File.read(path), binding)
    end

    def self.load(string, binding=nil)
      self.new YAML.parse(ERB.new(string).result(binding))
    end

  private
    def parse(node=nil, key=nil)
      case node.value
        when String
          if node.value =~ /^%{1}(.*)/
            node = parse(@data.select($1).first)
          end
          node.respond_to?(:transform) ? node.transform : node
        when Hash
          parsed = {}
          node.value.each do |k,v| 
            if k.value == "<<"
              node = parse(v)
              if node.is_a?(Hash)
                node.merge!(parsed)
              end
              parsed = node
            else
              parsed[k.value] = parse(v)
            end
          end
          parsed
        when Array
          parsed = []
          node.value.each do |v|
            node = parse(v)
            node.is_a?(Array) ? parsed.concat(node) : parsed.push(node)
          end
          parsed
      end
    end
  end
end