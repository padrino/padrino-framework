# frozen_string_literal: true

require 'rubygems'
require 'memory_profiler'
require 'yaml'
require 'ostruct'

template_path = File.expand_path('../fixtures/template.erb', __FILE__)
template = File.read(template_path)

context_path = File.expand_path('../fixtures/context.yml', __FILE__)
context = OpenStruct.new(YAML.load_file(context_path)).instance_eval { binding }

MemoryProfiler.report do
  case ENV['TARGET']
  when 'erubis'
    require 'erubis'
    erubis = Erubis::Eruby.new(template, :trim => false)
    erubis.result(context)
  when 'fast_erubis'
    require 'erubis'
    fast_erubis = Erubis::FastEruby.new(template, :trim => false)
    fast_erubis.result(context)
  when 'erubi'
    require 'erubi'
    erubi = Erubi::Engine.new(template, :trim => false)
    eval(erubi.src, context)
  when 'safe_erubi'
    require 'padrino/core_ext/output_safety'
    require 'erubi'
    class SafeErubi < Erubi::Engine
      def add_text(text)
        @src << " #{@bufvar}.safe_concat '" << text.gsub(/['\\]/, '\\\\\&') << "';" unless text.empty?
      end
    end
    erubi = SafeErubi.new(template, :trim => false, :bufval => "SafeBuffer.new")
    eval(erubi.src, context)
  when 'fast_safe_erb'
    require 'padrino/rendering/fast_safe_erb_engine'
    fast_safe_erb = Padrino::Rendering::FastSafeErbEngine.new(template)
    eval(fast_safe_erb.src, context)
  end
  nil
end.pretty_print
