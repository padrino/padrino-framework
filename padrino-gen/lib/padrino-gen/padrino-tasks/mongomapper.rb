if defined?(MongoMapper)
  begin
    require 'i18n'
  rescue LoadError
    # Only do this for I18n check later.
  end

  namespace :mm do
    desc 'Drops all the collections for the database for the current Padrino.env'
    task :drop => :environment do
      MongoMapper.database.collections.select {|c| c.name !~ /system/ }.each(&:drop)
    end

    desc "Generates .yml files for I18n translations"
    task :translate => :environment do
      models = Dir["#{Padrino.root}/{app,}/models/**/*.rb"].map { |m| File.basename(m, ".rb") }

      models.each do |m|
        # Get the model class.
        klass = m.camelize.constantize

        # Init the processing
        print "Processing #{m.humanize}: "
        FileUtils.mkdir_p("#{Padrino.root}/app/locale/models/#{m}")
        langs = Array(I18n.locale)

        # Create models for it and en locales.
        langs.each do |lang|
          filename   = "#{Padrino.root}/app/locale/models/#{m}/#{lang}.yml"
          columns    = klass.keys.values.map(&:name).reject { |name| name =~ /id/i }
          # If the lang file already exist we need to check it
          if File.exist?(filename)
            locale = File.open(filename).read
            columns.each do |c|
              locale += "\n        #{c}: #{c.humanize}" unless locale.include?("#{c}:")
            end
            print "Lang #{lang.to_s.upcase} already exist ... "; $stdout.flush
          else
            locale     = "#{lang}:" + "\n" +
                         "  models:" + "\n" +
                         "    #{m}:" + "\n" +
                         "      name: #{klass.human_name}" + "\n" +
                         "      attributes:" + "\n" +
                         columns.map { |c| "        #{c}: #{c.humanize}" }.join("\n")
            print "created a new for #{lang.to_s.upcase} Lang ... "; $stdout.flush
          end
          File.open(filename, "w") { |f| f.puts locale }
        end
        puts
      end
    end
  end

  task 'db:drop' => 'mm:drop'
end
