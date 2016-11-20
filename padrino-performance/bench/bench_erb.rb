require 'rubygems'
require 'benchmark/ips'
require 'erb'
require 'erubis'
require 'erubi'

$LOAD_PATH << File.expand_path('../../../padrino-helpers/lib', __FILE__)
require 'padrino/rendering/fast_safe_erb_engine'
require 'padrino/core_ext/output_safety'

class SafeErubi < Erubi::Engine
  def add_text(text)
    @src << " #{@bufvar}.safe_concat '" << text.gsub(/['\\]/, '\\\\\&') << "';" unless text.empty?
  end
end

require 'yaml'
require 'ostruct'
require 'benchmark'

Benchmark.ips do |x|
  x.config(:time => 1, :warmup => 0.1)

  m = 10

  template_path = File.expand_path('../fixtures/template.erb', __FILE__)
  template = File.read(template_path)

  context_path = File.expand_path('../fixtures/context.yml', __FILE__)
  context = OpenStruct.new(YAML.load_file(context_path)).instance_eval { binding }

  x.report("#{m}k erb    (compile+eval)") do
    (m*100).times do
      ERB.new(template).result(context)
    end
  end

  x.report("#{m}k erubis (compile+eval)") do
    (m*100).times do
      Erubis::Eruby.new(template, :trim => false).result(context)
    end
  end

  x.report("#{m}k erubi  (compile+eval)") do
    (m*100).times do
      eval(Erubi::Engine.new(template, :trim => false).src, context)
    end
  end

  erb = ERB.new(template)
  x.report("#{m}k erb            (eval)") do
    (m*100).times do
      erb.result(context)
    end
  end

  erubis = Erubis::Eruby.new(template, :trim => false)
  x.report("#{m}k erubis         (eval)") do
    (m*100).times do
      erubis.result(context)
    end
  end

  fast_erubis = Erubis::FastEruby.new(template, :trim => false)
  x.report("#{m}k fast erubis    (eval)") do
    (m*100).times do
      fast_erubis.result(context)
    end
  end

  erubi = Erubi::Engine.new(template, :trim => false)
  x.report("#{m}k erubi          (eval)") do
    (m*100).times do
      eval(erubi.src, context)
    end
  end

  safe_erubi = SafeErubi.new(template, :trim => false, :bufval => "SafeBuffer.new")
  x.report("#{m}k safe_erubi     (eval)") do
    (m*100).times do
      eval(safe_erubi.src, context)
    end
  end

  fase_safe_erb_src = Padrino::Rendering::FastSafeErbEngine.compile(template)
  x.report("#{m}k fast_safe_erb  (eval)") do
    (m*100).times do
      eval(fase_safe_erb_src, context)
    end
  end

  #
  # For inspection
  #

  File.open('erb.html', 'w') {|io| io << erb.result(context) }
  File.open('erb.src', 'w') {|io| io << erb.src }

  File.open('erubis.html', 'w') {|io| io << erubis.result(context) }
  File.open('erubis.src', 'w') {|io| io << erubis.src }

  File.open('fast_erubis.html', 'w') {|io| io << fast_erubis.result(context) }
  File.open('fast_erubis.src', 'w') {|io| io << fast_erubis.src }

  File.open('erubi.html', 'w') {|io| io << eval(erubi.src, context) }
  File.open('erubi.src', 'w') {|io| io << erubi.src }

  File.open('safe_erubi.html', 'w') {|io| io << eval(safe_erubi.src, context) }
  File.open('safe_erubi.src', 'w') {|io| io << safe_erubi.src }

  File.open('fase_safe_erb.html', 'w') {|io| io << eval(fase_safe_erb_src, context) }
  File.open('fase_safe_erb.src', 'w') {|io| io << fase_safe_erb_src }

  x.compare!
end
