# Frequently asked Questions

This section is for questions on all topics. Please check here before submitting an issue.

## Why is the `Mail` Object not available at the beginning of testing?

Padrino Mailers work with the [Mail Gem](https://github.com/mikel/mail). This gem is so slow at loading it is patched to lazy load[*](https://github.com/padrino/padrino-framework/blob/ca2825f0a6fd90e61f07d7a0112c79414b46b7e4/padrino-mailer/lib/padrino-mailer.rb#L44-L47). To solve this issue the mail gem can be required at the beginning of tests `require 'mail'`

**Example**

```rb
require '../test_config'
require 'mail' # Explicitly load Mail Gem

class MailTest < MiniTest::Test
  def setup
    app ProjectName::App do
      set :delivery_method, :test # emails are not sent and recorded in the test mailer
    end

    Mail::TestMailer.deliveries.clear # Unavailable pretesting unless mail required
  end

  def test_mail_is_sent
    get '/email_route'
    last_message = Mail::TestMailer.deliveries.pop
    assert last_message, 'Sent message exists'
    # Other assertions on last mail
  end
end