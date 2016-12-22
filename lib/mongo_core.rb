require 'active_support'
require 'active_support/core_ext'

module MongoCore
  class << self; attr_accessor :db, :schema, :caching, :debug; end

  # # # # # #
  # Default Options
  # # # # # #

  # Schema path is $app_root/config/db/schema/:model_name.yml
  @schema = File.join(Dir.pwd, 'config', 'db', 'schema')
  @caching = true
  @debug = true
end

require_relative 'mongo_core/document'
require_relative 'mongo_core/query'
require_relative 'mongo_core/cache'
