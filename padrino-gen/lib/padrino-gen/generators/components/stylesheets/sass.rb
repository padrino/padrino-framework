SASS_RAKE = <<~RAKE unless defined?(SASS_RAKE)
  # Dart Sass compiles each file in app/stylesheets to public/stylesheets, in the same folders:
  # app/stylesheets/application.scss becomes public/stylesheets/application.css.
  # Files whose names start with "_" are partials, compiled only into the stylesheets that @use them.
  # Plain .css files are copied as they are.
  SASS_ARGS = %w[--no-source-map --load-path=app/stylesheets app/stylesheets:public/stylesheets].freeze

  namespace :sass do
    desc 'Build public/stylesheets from the Sass and SCSS files in app/stylesheets'
    task :build do
      mkdir_p 'app/stylesheets', verbose: false
      sh Gem.ruby, Gem.bin_path('sass-embedded', 'sass'), *SASS_ARGS
    end

    desc 'Rebuild public/stylesheets whenever a file in app/stylesheets changes'
    task :watch do
      mkdir_p 'app/stylesheets', verbose: false
      sh Gem.ruby, Gem.bin_path('sass-embedded', 'sass'), '--watch', *SASS_ARGS
    end
  end

  namespace :assets do
    task precompile: 'sass:build'
  end
RAKE

# Also the scss component's setup: Dart Sass tells the two syntaxes apart by file extension.
def setup_stylesheet
  require_dependencies 'sass-embedded', version: '~> 1.63', require: false
  empty_directory destination_root('/app/stylesheets')
  create_file destination_root('tasks/sass.rake'), SASS_RAKE, skip: true

  watcher = "css: bundle exec rake sass:watch\n"
  procfile = destination_root('Procfile.dev')
  if !File.exist?(procfile)
    create_file procfile, "web: bundle exec padrino start\n#{watcher}"
  elsif !(content = File.binread(procfile)).match?(/^css:/n)
    append_line(procfile, watcher)
  elsif !content.match?(/^#{watcher.chomp}\r?$/n)
    say "Procfile.dev already runs a css: process; to rebuild stylesheets on change, make it `#{watcher.chomp}`.", :yellow
  end

  # Projects generated before Dart Sass keep Ruby Sass, which still compiles app/stylesheets on request, over Dart Sass's output.
  read = ->(path) { File.file?(file = destination_root(path)) ? File.binread(file) : nil }
  remove = []
  remove << "gem 'sass' from Gemfile" if gemfile_gems.include?('sass')
  delete = []
  app = read.call('app/app.rb').to_s
  %w[sass scss].each do |name|
    path = "config/initializers/#{name}.rb"
    initializer = read.call(path)
    delete << path if initializer&.include?('Sass::Plugin')
    # An initializer of the project's own with that name is what the register line loads.
    next if initializer && !initializer.include?('Sass::Plugin')

    register = "register #{name.capitalize}Initializer"
    remove << "`#{register}` from app/app.rb" if app.match?(/^\s*#{register}\b/n)
  end
  remove << '.sass-cache/* from .gitignore' if read.call('.gitignore').to_s.match?(%r{^/?\.sass-cache}n)
  steps = [("remove #{remove.join(' and ')}" if remove.any?), ("delete #{delete.join(' and ')}" if delete.any?)].compact
  say "This project still has Ruby Sass. To switch to Dart Sass, #{steps.join(', ')}, then run bundle install.", :yellow if steps.any?

  if File.exist?(destination_root('tasks/tailwind.rake'))
    say 'Switching from tailwind: tasks/tailwind.rake also writes public/stylesheets/application.css, and Dart Sass copies ' \
        "app/stylesheets/application.css (Tailwind's source) over it. Delete tasks/tailwind.rake, move the rules you keep from " \
        "app/stylesheets/application.css into a .scss or .sass file and delete it, remove gem 'tailwindcss-ruby' from Gemfile " \
        'and make the css: line in Procfile.dev `css: bundle exec rake sass:watch`.', :yellow
  end

  say 'Run `bundle exec rake sass:build` to compile app/stylesheets into public/stylesheets (or run Procfile.dev to rebuild on change).', :yellow
end
