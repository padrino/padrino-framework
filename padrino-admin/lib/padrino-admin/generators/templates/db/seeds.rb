# Seed add you the ability to populate your db.
# We provide you a basic shell for interaction with the end user.
# So try some code like below:
# 
#   name = shell.ask("What's your name?")
#   shell.say name
# 
email     = shell.ask "Which email do you want use for loggin into admin?"
password  = shell.ask "Tell me the password to use:"

shell.say ""

account = Account.create(:email => email, :password => password, :password_confirmation => password, :role => "admin")

if account.valid?
  shell.say "Perfect! Your account was created."
  shell.say ""
  shell.say "Now you can start your server with padrino start and then login into /admin with:"
  shell.say "   email: #{email}"
  shell.say "   password: #{password}"
  shell.say ""
  shell.say "That's all!"
else
  shell.say "Sorry but some thing went worng!"
  shell.say ""
  account.errors.full_messages.each { |m| shell.say "   - #{m}" }
end

shell.say ""