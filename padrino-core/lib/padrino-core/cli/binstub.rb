module Padrino
  ##
  # Replaces the current process with it's binstub.
  #
  def self.replace_with_binstub(executable)
    begin
      return if Bundler.definition.missing_specs.empty?
    rescue NameError, NoMethodError, Bundler::GemfileNotFound
      # Move forward
    end

    project_root = Dir.pwd
    until project_root.empty?
      break if File.file?(File.join(project_root, 'Gemfile'))
      project_root = project_root.rpartition('/').first
    end

    return unless %w[Gemfile .components].all? { |file| File.file?(File.join(project_root, file)) }

    binstub = File.join(project_root, 'bin', executable)
    if File.file?(binstub)
      exec Gem.ruby, binstub, *ARGV
    else
      # exit! skips the flush of buffered output, so write to the unbuffered stderr. Not warn: -W0 silences it.
      $stderr.puts 'Please run `bundle install && bundle binstubs --all` from your project root to generate bundle-specific executables'
      exit!
    end
  end
end
