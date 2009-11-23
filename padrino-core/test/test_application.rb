require File.dirname(__FILE__) + '/helper'

class TestApplication < Test::Unit::TestCase

  context 'for application functionality' do

    should 'check default options' do
      assert_match %r{test/helper.rb}, PadrinoTestApp.app_file
      assert_equal :test, PadrinoTestApp.environment
      assert PadrinoTestApp.raise_errors
      assert !PadrinoTestApp.logging
      assert PadrinoTestApp.sessions
      assert PadrinoTestApp.log_to_file
      assert 'PadrinoTestApp', PadrinoTestApp.app_name
    end

    should 'check padrino specific options' do
      assert !PadrinoTestApp.reload?
      assert 'padrino_test_app', PadrinoTestApp.app_name
      assert 'StandardFormBuilder', PadrinoTestApp.default_builder
      assert !PadrinoTestApp.flash
      assert !PadrinoTestApp.padrino_mailer
      assert !PadrinoTestApp.padrino_helpers
    end
  end
end