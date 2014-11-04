# Frequently asked Questions

This section is for questions on all topics. Please check here before submitting an issue.

## Does the Padrino Controller support any other resful routes as symbol shortcuts, apart from index?

No. Only `:index` is a special case. All other routes are defined by the symbol name as shown in the second example below.

**Example**

```rb
SampleBlog::App.controllers :things do
  get :index do
    # some code
  end

  get :index, :map => 'things/' do
    # equivalent route to index above
  end

  get :other do
    # some code
  end

  get :other, :map => 'things/other/' do
    # equivalent route to other above
  end
end

```

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
```

## How to test post routes, I keep getting a 403 forbidden response

A generated Padrino project includes csrf protect on all post requests. This should not be disabled at the app level, unless you know what you are doing. Csrf can be disable in an individual test suite by overwritting the `protect_from_csrf` setting

**Example**

```rb
require_relative '../test_config'

class ControllerTest < MiniTest::Test
  def setup
    app ProjectName::App do
      set :protect_from_csrf, false
    end
  end

  def test_post_to_server
    post '/request', data: 'information'
    refute_equal 403, last_response.status
    assert last_response.ok?
  end
end
```