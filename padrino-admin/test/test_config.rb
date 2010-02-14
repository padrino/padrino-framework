require 'helper'

class TestConfig < Test::Unit::TestCase

  should 'correctly generate a js function from yaml' do
    config = YAML.load <<-YAML
      alert: !js alert('foo bar')
      standard: json
    YAML
    assert_equal "{\"alert\":alert('foo bar'),\"standard\":\"json\"}", config.to_json
  end

end