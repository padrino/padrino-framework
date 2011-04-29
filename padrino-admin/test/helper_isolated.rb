require 'rubygems'
require 'test/unit'
require 'webrat'
require 'mechanize'
require 'nokogiri'
require 'rack'
require 'shoulda'
require 'ruby-debug'

class Test::Unit::TestCase
  include Webrat::Methods
  include Webrat::Matchers

  # No idea why we need this but without it response_code is not always recognized
  Webrat::Methods.delegate_to_session :response_code, :response_body

  # This is needed for webrat_steps.rb
  Webrat::Methods.delegate_to_session :response

  # More fast
  Mechanize.html_parser = Nokogiri::HTML

  Webrat.configure do |config|
    config.mode = :mechanize
  end

  def padrino(command, *args)
    path = File.expand_path('../../../padrino-core/bin/padrino', __FILE__)
    `#{Gem.ruby} #{path} #{command} #{args.join(" ")}`.strip
  end

  def padrino_gen(command, *args)
    path = File.expand_path('../../../padrino-gen/bin/padrino-gen', __FILE__)
    `#{Gem.ruby} #{path} #{command} #{args.join(" ")}`.strip
  end

  def bundle(cmd, *args)
    path = File.expand_path('../support/bundle', __FILE__)
    `#{Gem.ruby} #{path} #{cmd} #{args.join(" ")}`.strip
  end

  def replace_seed(path)
    File.open("#{path}/db/seeds.rb", "w") { |f| f.puts "Account.create(:email => 'info@padrino.com', :password => 'sample', :password_confirmation => 'sample', :role => 'admin')" }
  end

  def migrate(orm)
    case orm.to_sym
      when :activerecord then "ar:migrate"
      when :datamapper   then "dm:migrate"
      when :squel        then "sq:migrate"
      else ""
    end
  end
end

module Webrat
  class MechanizeAdapter
    # Suppress warnings
    def mechanize
      @mechanize ||= Mechanize.new
    end
  end

  module Logging
    # Suppress logger
    def logger
      @logger = nil
    end
  end
end