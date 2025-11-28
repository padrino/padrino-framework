require File.expand_path("#{File.dirname(__FILE__)}/helper")

describe 'Generator' do
  describe 'the generator' do
    it 'should have default generators' do
      %w[controller mailer migration model app plugin component task helper].each do |gen|
        assert Padrino::Generators.mappings.key?(gen.to_sym)
        assert_equal "Padrino::Generators::#{gen.camelize}", Padrino::Generators.mappings[gen.to_sym].name
        assert_respond_to Padrino::Generators.mappings[gen.to_sym], :start
      end
    end
  end
end
