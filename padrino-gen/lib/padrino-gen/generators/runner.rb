require 'fileutils'
require 'open-uri'

module Padrino
  module Generators
    ##
    # Responsible for executing plugin and template instructions including
    # common actions for modifying a project or application.
    #
    module Runner

      # Generates project scaffold based on a given template file.
      #
      # @param [Hash] options
      #   Options to use to generate the project.
      #
      # @example
      #   project :test => :shoulda, :orm => :activerecord, :renderer => "haml"
      #
      def project(options={})
        components = options.sort_by { |k, v| k.to_s }.map { |component, value| "--#{component}=#{value}" }
        params = [name, *components].push("-r=#{destination_root("../")}")
        say "=> Executing: padrino-gen project #{params.join(" ")}", :magenta
        Padrino.bin_gen(*params.unshift("project"))
      end

      ##
      # Executes generator command for specified type with given arguments.
      #
      # @param [Symbol] type
      #   Type of component module.
      # @param [String] arguments
      #   Arguments to send to component generator.
      #
      # @example
      #   generate :model, "post title:string body:text"
      #   generate :controller, "posts get:index get:new post:new"
      #   generate :migration, "AddEmailToUser email:string"
      #
      def generate(type, arguments="")
        params = arguments.split(" ").push("-r=#{destination_root}")
        params.push("--app=#{@_app_name}") if @_app_name
        say "=> Executing: padrino-gen #{type} #{params.join(" ")}", :magenta
        Padrino.bin_gen(*params.unshift(type))
      end

      ##
      # Executes rake command with given arguments.
      #
      # @param [String] command
      #   Rake tasks to execute.
      #
      # @example
      #   rake "custom task1 task2"
      #
      def rake(command)
        Padrino.bin("rake", command, "-c=#{destination_root}")
      end

      ##
      # Executes App generator. Accepts an optional block allowing generation inside subapp.
      #
      # @param [Symbol] name
      #   Name of (sub)application to generate.
      # @param [Proc] block
      #   Commands to execute in context of (sub)appliation directory.
      #
      # @example
      #   app :name
      #   app :name do
      #    generate :model, "posts title:string" # generate a model inside of subapp
      #   end
      #
      def app(name)
        say "=> Executing: padrino-gen app #{name} -r=#{destination_root}", :magenta
        Padrino.bin_gen(:app, name.to_s, "-r=#{destination_root}")
        if block_given?
          @_app_name = name
          yield
          @_app_name = nil
        end
      end

      ##
      # Executes git commmands in project.
      #
      # @param [Symbol] action
      #   Git command to execute.
      # @param [String] arguments
      #   Arguments to invoke on git command.
      #
      # @example
      #   git :init
      #   git :add, "."
      #   git :commit, "hello world"
      #
      def git(*args)
        FileUtils.cd(destination_root) do
          cmd = "git %s" % args.join(' ')
          say cmd, :green
          system cmd
        end
      end

      private

      ##
      # Resolves the path to the plugin template
      # given the project_name and the template_file.
      #
      # @param [Symbol] kind
      #   Context of template file to run, i.e :plugin, :template.
      # @param [String] template_file
      #   Path to template file.
      #
      # @example
      #   execute_runner(:plugin, 'path/to/local/file')
      #   execute_runner(:plugin, 'hoptoad')
      #   execute_runner(:template, 'sampleblog')
      #   execute_runner(:template, 'https://gist.github.com/357045')
      #
      def execute_runner(kind, template_file)
        # Determine resolved template path
        template_file = template_file.to_s
        template_path = case
          when template_file =~ %r{^https?://} && template_file !~ /gist/
            template_file
          when template_file =~ /gist/ && template_file !~ /raw/
            raw_link, _ = *URI.open(template_file) { |io| io.read.scan(/<a\s+href\s?\=\"(.*?)\"\>raw/) }
            raw_link ? "https://gist.github.com#{raw_link[0]}" : template_file
          when File.extname(template_file).empty? # referencing official plugin (i.e hoptoad)
            "https://raw.github.com/padrino/padrino-recipes/master/#{kind.to_s.pluralize}/#{template_file}_#{kind}.rb"
          else # local file on system
            File.expand_path(template_file)
          end
        begin
          self.apply(template_path)
        rescue => error
          say("The template at #{template_path} could not be loaded: #{error.message}", :red)
        end
      end
    end
  end
end
