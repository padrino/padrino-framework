require File.expand_path('../../helper', __FILE__)
require File.expand_path('../shared', __FILE__)

class FileStoreTest < BaseTest
  before do
    @apptmp = "#{Dir.tmpdir}/padrino-tests/#{UUID.new.generate}"
    FileUtils.mkdir_p(@apptmp)
    Padrino.cache = Padrino::Cache::Store::File.new(@apptmp)
    @test_key = "val_#{Time.now.to_i}"
    Padrino.cache.flush
  end

  after do
    Padrino.cache.flush
  end
  
  it_behaves_like :cacheable
end
