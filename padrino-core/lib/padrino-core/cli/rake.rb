require File.expand_path('../tasks', __dir__)
require 'rake'
require 'rake/dsl_definition'
require 'thor'
require 'securerandom' unless defined?(SecureRandom)
begin
  require 'padrino-gen'
rescue LoadError
  # do nothing if padrino-gen is not available
end

module PadrinoTasks
  def self.init(init=false)
    Padrino::Tasks.files.flatten.uniq.each { |rakefile| begin
                                                          Rake.application.add_import(rakefile)
                                                        rescue StandardError
                                                          puts "<= Failed load #{ext}"
                                                        end }
    load(File.expand_path('rake_tasks.rb', __dir__))
    Rake.application.load_imports
  end

  def self.use(task)
    tasks << task
  end

  def self.tasks
    @tasks ||= []
  end

  def self.load?(task, constant_present)
    if constant_present && !PadrinoTasks.tasks.include?(task)
      warn <<-WARNING
Loading #{task} tasks automatically.
This functionality will be disabled in future versions. Please put

  PadrinoTasks.use(#{task.inspect})
  PadrinoTasks.init

and remove

  require File.expand_path('../config/boot.rb', __FILE__)

in you Rakefile instead.
      WARNING
    end

    constant_present || PadrinoTasks.tasks.include?(task)
  end
end

def shell
  @_shell ||= Thor::Base.shell.new
end
