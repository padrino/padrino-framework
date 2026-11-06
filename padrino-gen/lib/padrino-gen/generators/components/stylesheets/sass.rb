# ceiling: a change to any file in app/stylesheets recompiles every stylesheet there, and files imported from
# elsewhere aren't watched; track each compile's loaded_urls if that gets slow or misses a change.
SASS_INIT = <<-'SASS' unless defined?(SASS_INIT)
    # Compiles the Sass and SCSS files in app/stylesheets to public/stylesheets with Dart Sass
    # (https://sass-lang.com/dart-sass) when a file there changes, so app/stylesheets/application.scss
    # is served as /stylesheets/application.css. Files whose names start with "_" are partials:
    # they are compiled into the stylesheets that use them, not on their own.
    require 'fileutils'
    source = Padrino.root('app/stylesheets')
    target = Padrino.root('public/stylesheets')
    lock = Mutex.new
    app.use Rack::Config do
      lock.synchronize do
        files = Dir.glob('**/*.{sass,scss}', base: source)
        changed = files.map { |file| File.mtime(File.join(source, file)) }.max
        files.reject { |file| File.basename(file).start_with?('_') }.each do |file|
          css = File.join(target, file.sub(/\.s[ac]ss\z/, '.css'))
          next if File.exist?(css) && File.mtime(css) >= changed

          output = begin
            Sass.compile(File.join(source, file), load_paths: [source]).css
          rescue Sass::CompileError => e
            # Show the error at the top of the pages that use this stylesheet, instead of failing each request.
            message = "#{e.message}\n#{e.sass_stack}".gsub(/["\\\n]/, '"' => '\"', '\\' => '\\\\', "\n" => '\A ')
            %(body::before { white-space: pre; font-family: monospace; content: "#{message}"; }\n)
          end
          # Write a whole file and rename it, so a request never gets a half-written stylesheet.
          FileUtils.mkdir_p(File.dirname(css))
          File.write(temp = "#{css}.#{Process.pid}.tmp", output)
          File.rename(temp, css)
        end
      end
    end
SASS

# Shared with the scss component, which names its initializer scss.
def setup_sass_stylesheet(name)
  require_dependencies 'sass-embedded', version: '~> 1.63'
  initializer name, SASS_INIT.chomp, skip: reapplying_component?(:stylesheet)
  empty_directory destination_root('/app/stylesheets')
  # Projects generated before Dart Sass keep their Ruby Sass initializer when the component is applied again.
  path = "config/initializers/#{name}.rb"
  file = destination_root(path)
  return unless File.exist?(file) && File.read(file).include?('Sass::Plugin')

  say "#{path} still uses Ruby Sass. To switch to Dart Sass, remove gem 'sass' from Gemfile, " \
      "delete #{path}, run bundle install and run this command again.", :yellow
end

def setup_stylesheet
  setup_sass_stylesheet(:sass)
end
