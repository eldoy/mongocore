require 'active_support'
require 'active_support/core_ext'

module MongoCore
  class << self; attr_accessor :db; end
end

require_relative 'mongo_core/document'
require_relative 'mongo_core/query'
