require_relative 'helper'
require_relative 'fixtures/markup_app/app'
require 'bigdecimal'

describe 'NumberHelpers' do
  include Padrino::Helpers::NumberHelpers

  def app
    MarkupDemo
  end

  def kilobytes(number)
    number * 1024
  end

  def megabytes(number)
    kilobytes(number) * 1024
  end

  def gigabytes(number)
    megabytes(number) * 1024
  end

  def terabytes(number)
    gigabytes(number) * 1024
  end

  describe 'for number helpers functionality' do
    it 'should display number_to_currency' do
      assert_equal '$1,234,567,890.50',        number_to_currency(1_234_567_890.50)
      assert_equal '$1,234,567,890.51',        number_to_currency(1_234_567_890.506)
      assert_equal '$1,234,567,892',           number_to_currency(1_234_567_891.60, { precision: 0 })
      assert_equal '$1,234,567,890.5',         number_to_currency(1_234_567_890.50, { precision: 1 })
      assert_equal '&pound;1234567890,50',     number_to_currency(1_234_567_890.50, { unit: '&pound;', separator: ',', delimiter: '' })
      assert_equal '$1,234,567,890.50',        number_to_currency('1234567890.50')
      assert_equal '1,234,567,890.50 K&#269;', number_to_currency('1234567890.50', { unit: 'K&#269;', format: '%n %u' })
      assert_equal '$x',                       number_to_currency('x')

      assert_nil number_to_currency(nil)
    end

    it 'should display  number_to_percentage' do
      assert_equal '100.000%',   number_to_percentage(100)
      assert_equal '100%',       number_to_percentage(100, { precision: 0 })
      assert_equal '302.06%',    number_to_percentage(302.0574, { precision: 2 })
      assert_equal '100.000%',   number_to_percentage('100')
      assert_equal '1000.000%',  number_to_percentage('1000')
      assert_equal 'x%',         number_to_percentage('x')
      assert_equal '1.000,000%', number_to_percentage(1000, delimiter: '.', separator: ',')

      assert_nil number_to_percentage(nil)
    end

    it 'should display  number_with_delimiter' do
      assert_equal '12,345,678',        number_with_delimiter(12_345_678)
      assert_equal '0',                 number_with_delimiter(0)
      assert_equal '123',               number_with_delimiter(123)
      assert_equal '123,456',           number_with_delimiter(123_456)
      assert_equal '123,456.78',        number_with_delimiter(123_456.78)
      assert_equal '123,456.789',       number_with_delimiter(123_456.789)
      assert_equal '123,456.78901',     number_with_delimiter(123_456.78901)
      assert_equal '123,456,789.78901', number_with_delimiter(123_456_789.78901)
      assert_equal '0.78901',           number_with_delimiter(0.78901)
      assert_equal '123,456.78',        number_with_delimiter('123456.78')
      assert_equal 'x',                 number_with_delimiter('x')
      assert_equal '-1,234,567,890,123', number_with_delimiter('-1234567890123')
      assert_equal '1,234x5,678', number_with_delimiter('1234x5678')
      assert_equal '1\\1234\\1567', number_with_delimiter(1_234_567, delimiter: '\\1')

      assert_nil number_with_delimiter(nil)
    end

    it 'should display number_with_delimiter in linear time' do
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      actual = number_with_delimiter('1' * 100_000)
      assert_operator Process.clock_gettime(Process::CLOCK_MONOTONIC) - started, :<, 2
      assert_equal "1#{',111' * 33_333}", actual
    end

    it 'should display number_with_delimiter with options' do
      assert_equal '12 345 678',    number_with_delimiter(12_345_678, delimiter: ' ')
      assert_equal '12,345,678-05', number_with_delimiter(12_345_678.05, separator: '-')
      assert_equal '12.345.678,05', number_with_delimiter(12_345_678.05, separator: ',', delimiter: '.')
      assert_equal '12.345.678,05', number_with_delimiter(12_345_678.05, delimiter: '.', separator: ',')
    end

    it 'should display number_with_precision' do
      assert_equal '111.235',    number_with_precision(111.2346)
      assert_equal '111.23',     number_with_precision(111.2346, precision: 2)
      assert_equal '111.00',     number_with_precision(111, precision: 2)
      assert_equal '111.235',    number_with_precision('111.2346')
      assert_equal '3268',       number_with_precision(32.6751 * 100.00, precision: 0)
      assert_equal '112',        number_with_precision(111.60, precision: 0)
      assert_equal '1234567892', number_with_precision(1_234_567_891.60, precision: 0)

      # Return non-numeric params unchanged.
      assert_equal 'x', number_with_precision('x')
      assert_nil number_with_precision(nil)
    end

    it 'should round a BigDecimal exactly in number_with_precision' do
      assert_equal '1.01',                  number_with_precision(BigDecimal('1.005'), precision: 2)
      assert_equal '-1.01',                 number_with_precision(BigDecimal('-1.005'), precision: 2)
      assert_equal '12345678901234567.89',  number_with_precision(BigDecimal('12345678901234567.89'), precision: 2)
      assert_equal '0.30000000000000000000', number_with_precision(BigDecimal('0.3'), precision: 20)
      assert_equal '13.00000',              number_with_precision(BigDecimal('13'), precision: 5)
      assert_equal '3',                     number_with_precision(BigDecimal('2.5'), precision: 0)
      assert_equal '-3',                    number_with_precision(BigDecimal('-2.5'), precision: 0)
      assert_equal '0.00',                  number_with_precision(BigDecimal('-0.001'), precision: 2)
      assert_equal '0.00',                  number_with_precision(BigDecimal('-0'), precision: 2)
      assert_equal '12.345.678.901.234.567,89',
                   number_with_precision(BigDecimal('12345678901234567.885'), precision: 2, separator: ',', delimiter: '.')
    end

    it 'should round a BigDecimal exactly in number_to_currency and number_to_percentage' do
      assert_equal '$1.01',                      number_to_currency(BigDecimal('1.005'))
      assert_equal '$12,345,678,901,234,567.89', number_to_currency(BigDecimal('12345678901234567.89'))
      assert_equal '4.001%',                     number_to_percentage(BigDecimal('4.0005'))
    end

    it 'should keep returning a BigDecimal it can not format unchanged' do
      [BigDecimal('NaN'), BigDecimal('Infinity'), BigDecimal('-Infinity'), BigDecimal('1e400')].each do |number|
        assert_same number, number_with_precision(number, precision: 2)
        assert_same number, number_to_currency(number)
      end
      [-1, 1.5].each do |precision|
        number = BigDecimal('12.345')
        assert_same number, number_with_precision(number, precision: precision)
      end
    end

    it 'should round a BigDecimal half away from zero whatever the BigDecimal rounding mode' do
      mode = BigDecimal.mode(BigDecimal::ROUND_MODE)
      BigDecimal.mode(BigDecimal::ROUND_MODE, BigDecimal::ROUND_HALF_EVEN)
      assert_equal '1.01', number_with_precision(BigDecimal('1.005'), precision: 2)
      assert_equal '3',    number_with_precision(BigDecimal('2.5'), precision: 0)
    ensure
      BigDecimal.mode(BigDecimal::ROUND_MODE, mode)
    end

    it 'should display number_with_precision with custom delimiter and separator' do
      assert_equal '31,83',     number_with_precision(31.826, precision: 2, separator: ',')
      assert_equal '1.231,83',  number_with_precision(1231.826, precision: 2, separator: ',', delimiter: '.')
    end

    it 'should not look up the locale when every format option is given' do
      I18n.backend.expects(:translate).never
      assert_equal '1.234.567,89',  number_with_precision(1_234_567.891, precision: 2, separator: ',', delimiter: '.')
      assert_equal '1.234.567,891', number_with_delimiter(1_234_567.891, separator: ',', delimiter: '.')
      assert_equal '1.235',         number_with_precision(1234.5, precision: 0, separator: ',', delimiter: '.')
      assert_equal '123457',        number_with_precision(1234.567, precision: 2, separator: '', delimiter: '')
      assert_equal '1234567,5',     number_with_delimiter(1_234_567.5, separator: ',', delimiter: '')
      assert_equal '1.234.5675',    number_with_delimiter(1_234_567.5, separator: '', delimiter: '.')
    end

    it 'should take the format options not given from the locale' do
      assert_equal '1234567,89',    number_with_precision(1_234_567.891, precision: 2, locale: :de)
      assert_equal '1234567.89',    number_with_precision(1_234_567.891, precision: 2, separator: '.', locale: :de)
      assert_equal '1 234 567,89',  number_with_precision(1_234_567.891, separator: ',', delimiter: ' ', locale: :de)
      assert_equal '1.234.567,891', number_with_delimiter(1_234_567.891, delimiter: '.', locale: :de)
      assert_equal '1 234 567,891', number_with_delimiter(1_234_567.891, delimiter: ' ', locale: :de)
      assert_equal '1.234.567;891', number_with_delimiter(1_234_567.891, separator: ';', locale: :de)
    end

    it 'should display number_to_human_size' do
      assert_equal '0 Bytes',   number_to_human_size(0)
      assert_equal '1 Byte',    number_to_human_size(1)
      assert_equal '3 Bytes',   number_to_human_size(3.14159265)
      assert_equal '123 Bytes', number_to_human_size(123.0)
      assert_equal '123 Bytes', number_to_human_size(123)
      assert_equal '1.2 KB',    number_to_human_size(1234)
      assert_equal '12.1 KB',   number_to_human_size(12_345)
      assert_equal '1.2 MB',    number_to_human_size(1_234_567)
      assert_equal '1.1 GB',    number_to_human_size(1_234_567_890)
      assert_equal '1.1 TB',    number_to_human_size(1_234_567_890_123)
      assert_equal '1025 TB',   number_to_human_size(terabytes(1025))
      assert_equal '444 KB',    number_to_human_size(kilobytes(444))
      assert_equal '1023 MB',   number_to_human_size(megabytes(1023))
      assert_equal '3 TB',      number_to_human_size(terabytes(3))
      assert_equal '1.18 MB',   number_to_human_size(1_234_567, precision: 2)
      assert_equal '3 Bytes',   number_to_human_size(3.14159265, precision: 4)
      assert_equal '123 Bytes', number_to_human_size('123')
      assert_equal '1.01 KB',   number_to_human_size(kilobytes(1.0123), precision: 2)
      assert_equal '1.01 KB',   number_to_human_size(kilobytes(1.0100), precision: 4)
      assert_equal '10 KB',     number_to_human_size(kilobytes(10.000), precision: 4)
      assert_equal '1 Byte',    number_to_human_size(1.1)
      assert_equal '10 Bytes',  number_to_human_size(10)

      assert_nil number_to_human_size(nil)
    end

    it 'should display number_to_human_size with options' do
      assert_equal '1.18 MB', number_to_human_size(1_234_567, precision: 2)
      assert_equal '3 Bytes', number_to_human_size(3.14159265, precision: 4)
      assert_equal '1.01 KB', number_to_human_size(kilobytes(1.0123), precision: 2)
      assert_equal '1.01 KB', number_to_human_size(kilobytes(1.0100), precision: 4)
      assert_equal '10 KB',   number_to_human_size(kilobytes(10.000), precision: 4)
      assert_equal '1 TB',    number_to_human_size(1_234_567_890_123, precision: 0)
      assert_equal '500 MB',  number_to_human_size(524_288_000, precision: 0)
      assert_equal '40 KB',   number_to_human_size(41_010, precision: 0)
      assert_equal '40 KB',   number_to_human_size(41_100, precision: 0)
    end

    it 'should display number_to_human_size with custom delimiter and separator' do
      assert_equal '1,01 KB',     number_to_human_size(kilobytes(1.0123), precision: 2, separator: ',')
      assert_equal '1,01 KB',     number_to_human_size(kilobytes(1.0100), precision: 4, separator: ',')
      assert_equal '1.000,1 TB',  number_to_human_size(terabytes(1000.1), delimiter: '.', separator: ',')
    end
  end
end
