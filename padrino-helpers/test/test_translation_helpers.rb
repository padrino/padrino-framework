require_relative 'helper'

describe 'TranslationHelpers' do
  include Padrino::Helpers::TranslationHelpers

  before do
    @locale = I18n.locale
    @enforce = I18n.enforce_available_locales
    I18n.enforce_available_locales = false
    I18n.backend.store_translations(
      :xx,
      date: { formats: { default: '%Y/%m/%d', short: '%d.%m' } },
      time: { formats: { default: '%H.%M.%S', short: '%H.%M' } }
    )
    I18n.backend.store_translations(
      :yy,
      date: { formats: { default: '%d-%m-%Y', short: '%m-%d' } }
    )
    I18n.locale = :xx
    @date = Date.new(2024, 3, 5)
    @time = Time.utc(2024, 3, 5, 14, 7, 9)
  end

  after do
    I18n.locale = @locale
    I18n.enforce_available_locales = @enforce
  end

  %i[l localize].each do |name|
    describe "##{name}" do
      it 'should localize a date without options' do
        assert_equal '2024/03/05', send(name, @date)
      end

      it 'should localize a time without options' do
        assert_equal '14.07.09', send(name, @time)
      end

      it 'should accept a symbol format' do
        assert_equal '05.03', send(name, @date, format: :short)
        assert_equal '14.07', send(name, @time, format: :short)
      end

      it 'should accept a string format' do
        assert_equal '2024-03-05', send(name, @date, format: '%Y-%m-%d')
        assert_equal '14:07:09', send(name, @time, format: '%H:%M:%S')
      end

      it 'should accept a locale' do
        assert_equal '05-03-2024', send(name, @date, locale: :yy)
      end

      it 'should accept a locale and a format' do
        assert_equal '03-05', send(name, @date, locale: :yy, format: :short)
      end

      it 'should accept an options hash' do
        assert_equal '05.03', send(name, @date, { format: :short })
      end
    end
  end
end
