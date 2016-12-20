require 'active_support'
require 'active_support/core_ext'

module MongoCore
  cattr_accessor :db
end

require_relative 'mongo_core/document'
require_relative 'mongo_core/query'
require_relative 'mongo_core/scope'
