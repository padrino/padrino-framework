require 'rubygems'
require 'yaml'
require 'erb'
require 'json/pure'

module ExtJs

  class ConfigError < RuntimeError; end

  # This class it's used for JSON variables.
  # Normally if we convert this { :function => "alert('Test')" } will be:
  # 
  #   { "function": "alert('Test')" }
  # 
  # But if in our javascript need to "eval" this function is not possible because
  # it's a string.
  # 
  # Using ExtJs::Variable the result will be:
  # 
  #   { "function" : alert('Test') }
  # 
  # Normally an ExtJs Variable can be handled with ExtJs Config like:
  # 
  #   function: !js alert('Test')
  # 
  class Variable < String
    yaml_as "tag:yaml.org,2002:js"

    def to_json(*a)
      self
    end
  end

  # This class it's used for write in a new and simple way json.
  # 
  # In ExtJs framework generally each component have a configuration written in json.
  # 
  # Write this config in ruby it's not the best choice think this example:
  # 
  #   # A Generic grid config in JavaScript:
  #   var gridPanel = new Ext.grid.GridPanel({
  #     bbar: gridPanelPagingToolbar,
  #     clicksToEdit: 1,
  #     cm: gridPanelColumnModel,
  #     region: "center",
  #     sm: gridPanelCheckboxSelectionModel,
  #     viewConfig: {"forceFit":true},
  #     plugins: [new Ext.grid.Search()],
  #     border: false,
  #     tbar: gridPanelToolbar,
  #     id: "grid-accounts",
  #     bodyBorder: false,
  #     store: gridPanelGroupingStore,
  #     view: gridPanelGroupingView
  #   });
  # 
  #   # A Gneric grid config in Ruby:
  #   { :bbar => ExtJs::Variable.new('gridPanelPagingToolbar'), :clicksToEdit => 1, 
  #     :cm => ExtJs::Variable.new('gridPanelColumnModel'), :region => "center",
  #     :sm => ExtJs::Variable.new('gridPanelCheckboxSelectionModel'),
  #     :viewConfig => { :forceFit => true }, plugins => [ExtJs::Variable.new('new Ext.grid.Search()'].
  #     :border => false ... continue 
  # 
  # As you can see writing json in pure ruby (in this case with hash) require much time and is
  # <tt>less</tt> readable.
  # 
  # For this reason we build an ExtJs Config, that basically it's an yaml file with
  # some new great functions so the example above will be:
  # 
  #   # A Generic grid config in ExtJs Config:
  #   gridPanel:
  #     bbar: !js gridPanelPagingToolbar
  #     clicksToEdit: 1,
  #     cm: !js gridPanelColumnModel
  #     region: center
  #     sm: !js gridPanelCheckboxSelectionModel
  #     viewConfig:
  #       forceFit: true
  #     plugins: [!js new Ext.grid.Search()]
  #     border: false
  #     tbar: !js gridPanelToolbar
  #     id: grid-accounts
  #     bodyBorder: false
  #     store: !js gridPanelGroupingStore
  #     view: !js gridPanelGroupingView
  # 
  # Now you see that it's more readable, simple and coincise!
  # 
  # But our ExtJs config can act also as an xml or an erb partial. See this code:
  # 
  #   # A template
  #   tempate:
  #     tbar:
  #       here: a custom config
  #     grid:
  #       viewConfig:
  #         forceFit: true
  #       plugins: [!js new Ext.grid.Search()]
  #       border: false  
  # 
  # We can "grep" this config in our template with:
  #   
  #   # A generic grid
  #   gridPanel:
  #     <<: %template/grid
  #     border: true
  # 
  # The result will be:
  # 
  #   gridPanel:
  #     viewConfig:
  #       forceFit: true
  #     plugins: [!js new Ext.grid.Search()]
  #     border: true # overidden
  # 
  # See our test for more complex examples.
  # 
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