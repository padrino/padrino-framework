#!/usr/bin/env ruby
# -*- encoding : UTF-8 -*-

system("rvm --force --default use system")

ENV['USER_RUBYGEMS'] = `which gem`.to_s
ENV['USER_RUBY'] = `which ruby`.to_s

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
  system("sudo $USER_RUBY -S $USER_RUBYGEMS install '/opt/padrino-framework/#{g}/pkg/#{g}-0.10.6.c.gem' -V")
end 
