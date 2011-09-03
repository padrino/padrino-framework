ENV['PADRINO_ENV'] = 'test'
PADRINO_ROOT = File.dirname(__FILE__) unless defined?(PADRINO_ROOT)

require File.expand_path('../../../load_paths', __FILE__)
require File.join(File.dirname(__FILE__), '..', '..', 'padrino-core', 'test', 'helper')
require 'padrino-cache'
require 'fileutils'
require 'uuid'

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
