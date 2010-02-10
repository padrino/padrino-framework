namespace :locale do
  desc "Create or update the app/models locale using your I18n.locale"
  task :models => :environment do
    models = Dir["#{Padrino.root}/app/models/**/*.rb"].collect { |m| File.basename(m, ".rb") }

    models.each do |m|
      # Get the model class
      klass = m.camelize.constantize
      next unless klass.respond_to?(:properties) || klass.respond_to?(:human_local_name) || klass.respond_to?(:human_local_attribute_name)

      # Init the processing
      print "Processing #{m.humanize}: "
      FileUtils.mkdir_p("#{Padrino.root}/app/locale/models/#{m}")
      langs = Array(I18n.locale) # for now we use only one

      # Create models for it and en locales
      langs.each do |lang|
        filename   = "#{Padrino.root}/app/locale/models/#{m}/#{lang}.yml"
        columns    = klass.properties.collect(&:name)
        # If the lang file already exist we need to check it
        if File.exist?(filename)
          locale = File.open(filename).read
          columns.each do |c|
            locale += "\n        #{c}: #{klass.human_local_attribute_name(c)}" unless locale.include?("#{c}:")
          end
          print "Lang #{lang.to_s.upcase} already exist ... "; $stdout.flush
          # Do some ere
        else
          locale     = "#{lang}:" + "\n" +
                       "  models:" + "\n" +
                       "    #{m}:" + "\n" +
                       "      name: #{klass.human_local_name}" + "\n" +
                       "      attributes:" + "\n" +
                       columns.collect { |c| "        #{c}: #{klass.human_local_attribute_name(c)}" }.join("\n")
          print "created a new for #{lang.to_s.upcase} Lang ... "; $stdout.flush
        end
        File.open(filename, "w") { |f| f.puts locale }
      end
      puts
    end
  end
end