require 'tilt'
require 'thor'
require 'padrino-core'
require 'padrino-gen'

Dir[File.dirname(__FILE__) + '/padrino-admin/*.rb'].each {|file| require file }
Dir[File.dirname(__FILE__) + '/padrino-admin/{helpers,adapters,ext_js,generators,utils}/*.rb'].each {|file| require file }

Padrino::Application.send(:cattr_accessor, :access_control)
Padrino::Application.send(:access_control=, Class.new(Padrino::AccessControl::Base))
String.send(:include, Padrino::Admin::Utils::Crypt)
String.send(:include, Padrino::Admin::Utils::Literal)

CarrierWave.root = Padrino.root if defined?(CarrierWave)

# Load our locales
I18n.load_path += Dir["#{File.dirname(__FILE__)}/padrino-admin/locale/**/*.yml"]