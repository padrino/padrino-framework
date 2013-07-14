ENV['PADRINO_ENV'] = 'test'
PADRINO_ROOT = File.dirname(__FILE__) unless defined?(PADRINO_ROOT)

require File.expand_path('../../../load_paths', __FILE__)
require File.join(File.dirname(__FILE__), '..', '..', 'padrino-core', 'test', 'helper')
require 'uuid'
require 'padrino-cache'
require 'fileutils'

class MiniTest::Spec

  def executable_on_path(binary)
    @matches = []

    ENV['PATH'].split(":").each do |path|
      bintest = File.executable?("#{path}/#{binary}")
      pathmatch = "#{path}/#{binary}"
      @matches << pathmatch if bintest == true
    end

    @matches.length == 1 ? @matches.first : false

  end
end

MiniTest::Spec.class_eval do
  def self.shared_examples
    @shared_examples ||= {}
  end
end

module MiniTest::Spec::SharedExamples
  def shared_examples_for(desc, &block)
    MiniTest::Spec.shared_examples[desc] = block
  end
 
  def it_behaves_like(desc)
    self.instance_eval do
      MiniTest::Spec.shared_examples[desc].call
    end
  end
end
 
Object.class_eval { include(MiniTest::Spec::SharedExamples) }
