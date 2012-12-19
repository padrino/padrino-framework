require 'bundler/setup'
require 'padrino-core'
require 'slim'

module FakeMail
  extend self
  include Padrino::Templates

  set :views, File.expand_path('../views', __FILE__)

  def mail_template
    slim 'h1 Hello HTML'
  end

  def page_template
    slim :page
  end
end

p FakeMail.mail_template
p FakeMail.page_template
