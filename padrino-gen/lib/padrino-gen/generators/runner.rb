require 'fileutils'

module Padrino
  module Generators
    module Runner

      # Generates project scaffold based on a given template file
      # project :test => :shoulda, :orm => :activerecord, :renderer => "haml"
      def project(options={})
        components = options.ordered_collect { |component,value| "--#{component}=#{value}" }
        params = [name, *components].push("-r=#{destination_root("../")}")
        say "=> Executing: padrino-gen #{name} #{params.join(" ")}", :magenta
        Padrino.bin_gen(*params.unshift("project"))
      end

      # Executes generator command for specified type with given arguments
      # generate :model, "post title:string body:text"
      # generate :controller, "posts get:index get:new post:new"
      # generate :migration, "AddEmailToUser email:string"
      def generate(type, arguments="")
        params = arguments.split(" ").push("-r=#{destination_root}")
        params.push("--app=#{@_app_name}") if @_app_name
        say "=> Executing: padrino-gen #{type} #{params.join(" ")}", :magenta
        Padrino.bin_gen(*params.unshift(type))
      end

      # Executes rake command with given arguments
      # rake "custom task1 task2"
      def rake(command)
        Padrino.bin("rake", command, "-c=#{destination_root}")
      end

      # Executes App generator. Accepts an optional block allowing generation inside subapp.
      # app :name
      # app :name do
      #  generate :model, "posts title:string"
      # end
      def app(name, &block)
        say "=> Executing: padrino-gen app #{name} -r=#{destination_root}", :magenta
        Padrino.bin_gen(:app, name.to_s, "-r=#{destination_root}")
        if block_given?
          @_app_name = name
          block.call
          @_app_name = nil
        end
      end

      # Executes git commmands in project using Grit
      # git :init
      # git :add, "."
      # git :commit, "hello world"
      def git(action, arguments=nil)
        FileUtils.cd(destination_root) do
          require 'git' unless defined?(::Git)
          if action.to_s == 'init'
            ::Git.init(arguments || destination_root)
            say "Git repo has been initialized", :green
          else
            @_git ||= ::Git.open(destination_root)
            @_git.method(action).call(arguments)
          end
        end
      end

      private

      # Resolves the path to the plugin template
      # given the project_name and the template_file
      # execute_runner(:plugin, 'path/to/local/file')
      # execute_runner(:plugin, 'hoptoad')
      # execute_runner(:template, 'sampleblog')
      # execute_runner(:template, 'http://gist.github.com/357045')
      def execute_runner(kind, template_file)
        # Determine resolved template path
        template_path = case
        when template_file =~ %r{^http://} && template_file !~ /gist/
          template_file
        when template_file =~ /gist/ && template_file !~ /raw/
          raw_link = open(template_file).read.scan(/<a\s+href\s?\=\"(.*?)\"\>raw/)
          raw_link ? "http://gist.github.com#{raw_link}" : template_file
        when File.extname(template_file).blank? # referencing official plugin (i.e hoptoad)
          "http://github.com/padrino/padrino-recipes/raw/master/#{kind.to_s.pluralize}/#{template_file}_#{kind}.rb"
        else # local file on system
          File.expand_path(template_file)
        end
        self.apply(template_path)
      end
    end # Runner
  end # Generators
end # Padrino
