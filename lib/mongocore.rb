require 'active_support'
require 'active_support/core_ext'

module Mongocore

  # # # # # #
  # Mongocore Ruby Database Driver.
  # @homepage: https://github.com/fugroup/mongocore
  # @author:   Vidar <vidar@fugroup.net>, Fugroup Ltd.
  # @license:  MIT, contributions are welcome.
  # # # # # #

  class << self; attr_accessor :db, :schema, :cache, :access, :timestamps, :debug; end

  # Schema path is $app_root/config/db/schema/:model_name.yml
  @schema = File.join(Dir.pwd, 'config', 'db', 'schema')

  # Enable the query cache
  @cache = false

  # Enabled the access control for keys
  @access = true

  # Enable timestamps, adds created_at and updated fields to your model
  # The fields are automatically updated when you save your model
  @timestamps = true

  # Debug option
  @debug = false
end

require_relative 'mongocore/document'
require_relative 'mongocore/query'
require_relative 'mongocore/schema'
require_relative 'mongocore/access'
require_relative 'mongocore/cache'
require_relative 'mongocore/filters'

# Info on MongoDB Driver
# https://docs.mongodb.com/ruby-driver/master/quick-start/
# http://zetcode.com/db/mongodbruby/
# http://recipes.sinatrarb.com/p/databases/mongo
# https://github.com/steveren/ruby-driver-sample-app/blob/master/lib/neighborhood.rb

# Indexing
# Mongocore.db[:profiles].indexes.create_one({:key => 1}, :unique => true)
