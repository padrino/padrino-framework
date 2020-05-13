module Padrino
  ##
  # Replaces the current process with it's binstub.
  #
  def self.replace_with_binstub(executable)
    begin
      return if Bundler.definition.missing_specs.empty?
    rescue NameError, NoMethodError, Bundler::GemfileNotFound
    end

    project_root = Dir.pwd
    until project_root.empty?
      break if File.file?(File.join(project_root, 'Gemfile'))
      project_root = project_root.rpartition('/').first
    end

    if %w(Gemfile .components).all? { |file| File.file?(File.join(project_root, file)) }
      binstub = File.join(project_root, 'bin', executable)
      if File.file?(binstub)
        exec Gem.ruby, binstub, *ARGV
      else
        puts 'Please run `bundle install --binstubs` from your project root to generate bundle-specific executables'
        exit!
      end
    end
  end
end
