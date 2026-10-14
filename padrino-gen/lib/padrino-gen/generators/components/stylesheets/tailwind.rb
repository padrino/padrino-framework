TAILWIND_CSS = <<~CSS unless defined?(TAILWIND_CSS)
  @import "tailwindcss";
CSS

TAILWIND_RAKE = <<~RAKE unless defined?(TAILWIND_RAKE)
  require 'tailwindcss/ruby'

  TAILWIND_ARGS = %w[-i app/stylesheets/application.css -o public/stylesheets/application.css].freeze

  namespace :tailwind do
    desc 'Build public/stylesheets/application.css from app/stylesheets/application.css'
    task :build do
      sh Tailwindcss::Ruby.executable, *TAILWIND_ARGS, '--minify'
    end

    desc 'Rebuild public/stylesheets/application.css whenever the app changes'
    task :watch do
      sh Tailwindcss::Ruby.executable, *TAILWIND_ARGS, '--watch=always'
    end
  end

  namespace :assets do
    task precompile: 'tailwind:build'
  end
RAKE

def setup_stylesheet
  # Start on a new line so a file without a trailing newline keeps its last line intact.
  append_line = lambda do |path, text|
    content = File.read(path)
    append_file path, content.empty? || content.end_with?("\n") ? text : "\n#{text}"
  end

  require_dependencies 'tailwindcss-ruby', version: '~> 4.0'
  # Tailwind writes its build to public/stylesheets/application.css, so carry
  # any hand-written styles there over into a new source file instead of losing them.
  # Once the source exists, that file is build output and must not be merged again.
  source = destination_root('app/stylesheets/application.css')
  existing = destination_root('public/stylesheets/application.css')
  if !File.exist?(source) && File.exist?(existing)
    css = File.read(existing)
    # Browsers ignore @charset and @import after other rules, so keep them above Tailwind's import,
    # with relative imports pointing back at public/stylesheets from the new location.
    head = css[%r{\A(?:\s+|/\*.*?\*/|@(?:charset|import)\b[^;]*;)*}m]
    imports = head.strip.gsub(/(@import\s+(?:url\(\s*)?["']?)([^"')\s;]+)/) do
      prefix, path = Regexp.last_match.captures
      "#{prefix}#{'../../public/stylesheets/' unless path.match?(%r{\A(?:[a-z][a-z0-9+.-]*:|/)}i)}#{path}"
    end
    create_file source, "#{imports}#{"\n" unless imports.empty?}#{TAILWIND_CSS}\n#{css[head.size..]}"
    remove_file existing
  else
    create_file source, TAILWIND_CSS, skip: true
  end
  create_file destination_root('tasks/tailwind.rake'), TAILWIND_RAKE, skip: true

  procfile = destination_root('Procfile.dev')
  if File.exist?(procfile)
    append_line.call(procfile, "css: bundle exec rake tailwind:watch\n") unless File.read(procfile).match?(/^css:/)
  else
    create_file procfile, "web: bundle exec padrino start\ncss: bundle exec rake tailwind:watch\n"
  end

  gitignore = destination_root('.gitignore')
  append_line.call(gitignore, "public/stylesheets/application.css\n") if File.exist?(gitignore)

  renderer = fetch_component_choice(:renderer).to_s
  renderer = 'erb' unless %w[haml slim].include?(renderer)
  tag = renderer == 'erb' ? "<%= stylesheet_link_tag 'application' %>" : "= stylesheet_link_tag 'application'"
  say 'Run `bundle exec rake tailwind:build` to build public/stylesheets/application.css (or run Procfile.dev to rebuild on change),', :yellow
  say "then add to the <head> of your layout (app/views/layouts/application.#{renderer}):", :yellow
  say "  #{tag}", :yellow
end
