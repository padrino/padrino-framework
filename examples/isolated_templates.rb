require 'bundler/setup'
require 'padrino-core'
require 'slim'

module Templater1
  include Padrino::Templates

  # Inherit templates
  template(:hello){ 'h1 Hello World!' }

  def self.page_template
    slim :page
  end
end

class Templater2
  include Templater1

  def self.page_custom
    slim :hello, layout: false
  end
end

class Templater3 < Templater2

  def self.page_cool
    slim :hello
  end
end

p Templater1.page_template
p Templater2.page_custom
p Templater3.page_cool
