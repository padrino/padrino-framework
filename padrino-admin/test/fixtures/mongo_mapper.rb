require 'mongo_mapper'

MongoMapper.connection = Mongo::Connection.new("127.0.0.1")
MongoMapper.database = 'test'

class Account
  include MongoMapper::Document
  key :name, String
end

Account.collection.remove
Padrino::Admin::Adapters.register(:mongomapper)