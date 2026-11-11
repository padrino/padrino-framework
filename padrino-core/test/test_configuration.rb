require_relative 'helper'

describe 'PadrinoConfiguration' do
  it 'should be able to store values' do
    Padrino.config.val1 = 12_345
    assert_equal 12_345, Padrino.config.val1
  end

  it 'should be able to configure with block' do
    Padrino.configure do |config|
      config.val2 = 54_321
    end
    assert_equal 54_321, Padrino.config.val2
  end

  it 'should be able to configure with block' do
    Padrino.configure :test do |config|
      config.test1 = 54_321
    end
    Padrino.configure :development do |config|
      config.test1 = 12_345
    end
    Padrino.configure :test, :development do |config|
      config.both1 = 54_321
    end
    assert_equal 54_321, Padrino.config.test1
    assert_equal 54_321, Padrino.config.both1
  end

  describe 'Padrino.config' do
    before do
      @saved_config = Padrino.instance_variable_get(:@config)
      Padrino.instance_variable_set(:@config, nil)
    end

    after do
      Padrino.instance_variable_set(:@config, @saved_config)
    end

    let(:config) { Padrino.config }

    it 'should read nil for a name that was never set' do
      assert_nil config.missing
      assert_nil config[:missing]
      assert_nil config.missing?
    end

    it 'should read and write the same value as an attribute, a Symbol key or a String key' do
      config.one = 1
      config[:two] = 2
      config['three'] = 3
      assert_equal [1, 2, 3], [config[:one], config['two'], config.three]
      assert_equal 4, config.send(:four=, 4)
    end

    it 'should store names that are private or missing methods on Object' do
      config.name = 'blog'
      config.test = 'minitest'
      config.format = 'json'
      assert_equal %w[blog minitest json], [config.name, config.test, config.format]
    end

    it 'should keep its own methods when a value has the same name' do
      config[:hash] = 'sha256'
      config.class = 'premium'
      assert_kind_of Integer, config.hash
      assert_same Padrino::Configuration::Store, config.class
      assert_equal %w[sha256 premium], [config[:hash], config[:class]]
    end

    it 'should respond to the reader and writer of a name once it is set' do
      refute_respond_to config, :port
      refute_respond_to config, :port=
      config.port = nil
      assert_respond_to config, :port
      assert_respond_to config, :port=
    end

    it 'should return a copy of its values from to_h' do
      config.a = 1
      hash = config.to_h
      hash[:b] = 2
      assert_equal({ a: 1 }, config.to_h)
      assert_equal({ 'a' => 2 }, config.to_h { |key, value| [key.to_s, value + 1] })
    end

    it 'should yield each name and value from each_pair' do
      config.a = 1
      config.b = 2
      pairs = []
      assert_same(config, config.each_pair { |key, value| pairs << [key, value] })
      assert_equal [[:a, 1], [:b, 2]], pairs
      assert_equal 2, config.each_pair.size
      assert_equal pairs, config.each_pair.to_a
    end

    it 'should dig into nested values' do
      config.database = { pool: [5, 10] }
      assert_equal 10, config.dig(:database, :pool, 1)
      assert_equal 5, config.dig('database', :pool, 0)
      assert_nil config.dig(:missing, :pool)
    end

    it 'should delete a field and return its value' do
      config.a = 1
      assert_equal 1, config.delete_field('a')
      assert_nil config.a
      refute_respond_to config, :a
      assert_raises(NameError) { config.delete_field(:a) }
      assert_equal :default, config.delete_field(:a) { :default }
    end

    it 'should equal another configuration with the same values' do
      other = config.class.new
      config.a = 1
      other.a = 1
      assert_equal other, config
      other.a = 2
      refute_equal other, config
      refute_equal({ a: 1 }, config)
    end

    it 'should be eql and hash alike when its values are eql' do
      other = config.class.new
      config.a = 1
      other.a = 1
      assert config.eql?(other)
      assert_equal config.hash, other.hash
      assert_equal :found, { config => :found }[other]
      other.a = 1.0
      refute config.eql?(other)
    end

    it 'should give a dup or a clone its own values' do
      config.a = 1
      copies = [config.dup, config.clone]
      copies.each { |copy| copy.a = 2 }
      assert_equal 1, config.a
      assert_equal [2, 2], copies.map(&:a)
    end

    it 'should keep a clone of a frozen configuration frozen and a dup writable' do
      config.a = 1
      config.freeze
      assert_raises(FrozenError) { config.clone.a = 2 }
      copy = config.dup
      copy.a = 2
      assert_equal [2, 1], [copy.a, config.a]
    end

    it 'should list its values in inspect and to_s' do
      config.a = 1
      config.b = 'x'
      assert_equal "#<#{config.class} a=1, b=\"x\">", config.inspect
      assert_equal config.inspect, config.to_s
    end

    it 'should raise on a write once frozen' do
      config.a = 1
      config.freeze
      assert_raises(FrozenError) { config.a = 2 }
      assert_raises(FrozenError) { config.b = 2 }
      assert_equal 1, config.a
    end

    it 'should raise NoMethodError for an unset name called with arguments' do
      assert_raises(NoMethodError) { config.missing(1) }
    end
  end

  it 'should read and write logger and display like other names' do
    config = Padrino::Configuration::Store.new
    assert_nil config.logger
    refute config.respond_to?(:logger)
    config.logger = :mine
    config.display = true
    assert_equal :mine, config.logger
    assert_equal true, config.display
    assert config.respond_to?(:logger)
  end

  it 'should not equal a Hash with the same values' do
    config = Padrino::Configuration::Store.new
    config.a = 1
    refute config == { a: 1 }
  end
end
