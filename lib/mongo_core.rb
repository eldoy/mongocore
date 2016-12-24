require 'active_support'
require 'active_support/core_ext'

module MongoCore

  # # # # # #
  # Default Options
  # # # # # #

  class << self; attr_accessor :db, :schema, :cache, :access, :debug; end

  # Schema path is $app_root/config/db/schema/:model_name.yml
  @schema = File.join(Dir.pwd, 'config', 'db', 'schema')
  @cache = false
  @access = true
  @debug = false
end

require_relative 'mongo_core/document'
require_relative 'mongo_core/query'
require_relative 'mongo_core/access'
