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

def base_name(file)
  File.basename(file,'.rb').gsub(/\-/, '_')
end

# --------------------------------------------------
# Watchr Rules
# --------------------------------------------------

# Padrino-Admin
watch("^padrino-admin/(.*)") do |m|
  if m[1] =~ /generators/
    run("ruby padrino-admin/test/generators/test_#{base_name(m[1])}_generator.rb")
  else
    run("ruby padrino-admin/test/test_admin_application.rb")
  end
end
# Padrino-Cache
watch("^padrino-cache.*/(.*)\.rb") { |m| run("ruby padrino-cache/test/test_#{base_name(m[1])}.rb")}
# Padrino-Core
watch("^padrino-core.*/(.*)\.rb") { |m| run("ruby padrino-core/test/test_#{base_name(m[1])}.rb")}
# Padrino-Gen
watch("^padrino-gen/lib/padrino-gen/generators/cli.rb") { |m| run("ruby padrino-gen/test/test_cli.rb") }
watch("^padrino-gen/lib/padrino-gen/generators/(.*)\.rb") { |m| run("ruby padrino-gen/test/test_#{base_name(m[1])}_generator.rb")}
# Padrino-Helpers
watch("^padrino-helpers/lib/padrino-helpers/(.*)\.rb") { |m| run("ruby padrino-helpers/test/test_#{base_name(m[1])}.rb")}
# Padrino-Mailer
watch("^padrino-mailer/lib/padrino-mailer/(.*)\.rb") { |m| run("ruby padrino-mailer/test/test_#{base_name(m[1])}.rb")}

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