#
# install watchr
# $ sudo gem install watchr
# 
# Run With:
# $ watchr test.watchr
#

# --------------------------------------------------
# Helpers
# --------------------------------------------------

def run(cmd)
  puts(cmd)
  system(cmd)
end

def run_all_tests
  system( "rake test" )
end

def sudo(cmd)
  run("sudo #{cmd}")
end

# --------------------------------------------------
# Watchr Rules
# --------------------------------------------------

# Padrino-Admin
watch("^padrino-admin/lib/generators/(.*)\.rb") { |m| run("ruby padrino-admin/test/generators/test_#{File.basename(m[1],'.rb')}_generator.rb")}
watch("^padrino-admin/(.*)") { |m| run("ruby padrino-admin/test/test_admin_application.rb")}
# Padrino-Cache
watch("^padrino-cache.*/(.*)\.rb") { |m| run("ruby padrino-cache/test/test_#{File.basename(m[1],'.rb')}.rb")}
# Padrino-Core
watch("^padrino-core.*/(.*)\.rb") { |m| run("ruby padrino-core/test/test_#{File.basename(m[1],'.rb')}.rb")}
# Padrino-Gen
watch("^padrino-gen/lib/padrino-gen/generators/cli.rb") { |m| run("ruby padrino-gen/test/test_cli.rb") }
watch("^padrino-gen/lib/padrino-gen/generators/(.*)\.rb") { |m| run("ruby padrino-gen/test/test_#{File.basename(m[1],'.rb')}_generator.rb")}
# Padrino-Helpers
watch("^padrino-helpers/lib/padrino-helpers/(.*)\.rb") { |m| run("ruby padrino-helpers/test/test_#{File.basename(m[1],'.rb')}.rb")}
# Padrino-Mailer
watch("^padrino-mailer/lib/padrino-mailer/(.*)\.rb") { |m| run("ruby padrino-mailer/test/test_#{File.basename(m[1],'.rb')}.rb")}

# any tests in test folder.
watch("^(.*)/test/(.*)") { |m| run("ruby #{m[1]}/test/#{m[2]}")}

# --------------------------------------------------
# Signal Handling
# --------------------------------------------------
# Ctrl-\
Signal.trap('QUIT') do
  puts " --- Running all tests ---\n\n"
  run_all_tests
end
 
# Ctrl-C
Signal.trap('INT') { abort("\n") }