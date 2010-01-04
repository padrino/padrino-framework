require 'mongo_mapper'

MongoMapper.connection = Mongo::Connection.new("127.0.0.1")
MongoMapper.database = 'test'

class MmAccount
  include MongoMapper::Document
  key :name, String
end

MmAccount.collection.remove
Padrino::Admin::Adapters.register(:mongo_mapper, MmAccount)