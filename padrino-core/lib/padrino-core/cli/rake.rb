require File.expand_path('../../tasks', __FILE__)
require 'rake'
require 'rake/dsl_definition'
require 'thor'
begin
  require 'securerandom' unless defined?(SecureRandom)
rescue LoadError
  # Fail silently
end
require 'padrino-gen'

module PadrinoTasks
  def self.init(init=false)
    Padrino::Tasks.files.flatten.uniq.each { |rakefile| Rake.application.add_import(rakefile) rescue puts "<= Failed load #{ext}" }
    if init
      Rake.application.init
      Rake.application.instance_variable_set(:@rakefile, __FILE__)
      load(File.expand_path('../rake_tasks.rb', __FILE__))
      Rake.application.load_imports
      Rake.application.top_level
    else
      load(File.expand_path('../rake_tasks.rb', __FILE__))
      Rake.application.load_imports
    end
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
