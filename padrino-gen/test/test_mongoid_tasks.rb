require_relative 'helper'
require 'open3'
require 'tmpdir'

describe 'Mongoid rake tasks' do
  # Runs mi:create_indexes in a separate process against a stand-in for the
  # mongoid gem, from a project root holding the given model files.
  def run_create_indexes(fake_mongoid, models)
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, 'mongoid.rb'), fake_mongoid)
      models.each do |path, body|
        FileUtils.mkdir_p(File.dirname(File.join(dir, path)))
        File.write(File.join(dir, path), body)
      end
      tasks = File.expand_path('../lib/padrino-gen/padrino-tasks/mongoid.rb', __dir__)
      script = <<~RUBY
        require 'padrino-core/cli/rake'
        PadrinoTasks.use(:mongoid)
        task(:environment) { #{models.keys.inspect}.each { |file| require File.expand_path(file) } }
        load #{tasks.inspect}
        Rake::Task['mi:create_indexes'].invoke
      RUBY
      env = { 'BUNDLE_GEMFILE' => File.expand_path('../../Gemfile', __dir__) }
      Open3.capture3(env, RbConfig.ruby, '-I', dir, '-e', script, chdir: dir)
    end
  end

  def model(name)
    <<~RUBY
      class #{name}
        include Mongoid::Document
        def self.embedded; false; end
        def self.create_indexes; puts 'GLOBBED #{name}'; end
      end
    RUBY
  end

  it 'should delegate to Mongoid::Tasks::Database when Mongoid provides it' do
    fake_mongoid = <<~RUBY
      module Mongoid
        VERSION = '9.1.1'
        module Document; end
        module Tasks
          module Database
            def self.create_indexes
              puts 'DELEGATED'
            end
          end
        end
      end
    RUBY
    out, err, status = run_create_indexes(fake_mongoid, 'app/models/account.rb' => model('Account'))
    assert status.success?, err
    assert_equal ['DELEGATED'], out.lines.map(&:strip).grep(/\A(DELEGATED|GLOBBED)\b/)
  end

  it 'should index the models found in app/models and models without Mongoid::Tasks::Database' do
    fake_mongoid = <<~RUBY
      module Mongoid
        VERSION = '3.1.7'
        module Document; end
      end
      # Stand-ins for the ActiveSupport inflections Mongoid loads.
      class String
        def classify; capitalize; end
        def constantize; Object.const_get(self); end
      end
    RUBY
    models = { 'app/models/account.rb' => model('Account'), 'models/user.rb' => model('User') }
    out, err, status = run_create_indexes(fake_mongoid, models)
    assert status.success?, err
    assert_equal ['GLOBBED User', 'GLOBBED Account'], out.lines.map(&:strip).grep(/\A(DELEGATED|GLOBBED)\b/)
  end
end
