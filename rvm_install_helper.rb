#!/usr/bin/env ruby
# -*- encoding : UTF-8 -*-

gem = %w[
  padrino-core
  padrino-gen
  padrino-helpers
  padrino-mailer
  padrino-admin
  padrino-cache
  padrino
]

gem.each do |g|
  system("gem install '/opt/padrino-framework/#{g}/pkg/#{g}-0.10.6.c.gem'")
  #system("rvm --force use ruby-head && sudo rvm --force --default gemset use global && rvmsudo gem install '/opt/padrino-framework/#{g}/pkg/#{g}-0.10.6.c.gem'")
  #system("rvm --force use ruby-1.8.7-p352 && sudo rvm --force --default gemset use global && rvmsudo gem install '/opt/padrino-framework/#{g}/pkg/#{g}-0.10.6.c.gem'")
  #system("rvm --force use ruby-1.9.3-rc1 && sudo rvm --force --default gemset use global && rvmsudo gem install '/opt/padrino-framework/#{g}/pkg/#{g}-0.10.6.c.gem'")
  #system("rvm --force use ruby-1.9.3-head && sudo rvm --force --default gemset use global && rvmsudo gem install '/opt/padrino-framework/#{g}/pkg/#{g}-0.10.6.c.gem'")
  #system("rvm --force use ruby-1.9.3-p125 && sudo rvm --force --default gemset use global && rvmsudo gem install '/opt/padrino-framework/#{g}/pkg/#{g}-0.10.6.c.gem'")
end 
