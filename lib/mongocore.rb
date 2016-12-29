require 'active_support'
require 'active_support/core_ext'

module Mongocore

  # # # # # #
  # Mongocore Ruby Database Driver.
  # @homepage: https://github.com/fugroup/mongocore
  # @author:   Vidar <vidar@fugroup.net>, Fugroup Ltd.
  # @license:  MIT, contributions are welcome.
  # # # # # #

  class << self; attr_accessor :db, :schema, :cache, :access, :debug; end

  # Schema path is $app_root/config/db/schema/:model_name.yml
  @schema = File.join(Dir.pwd, 'config', 'db', 'schema')
  @cache = true
  @access = true
  @debug = false
end

require_relative 'mongocore/document'
require_relative 'mongocore/query'
require_relative 'mongocore/schema'
require_relative 'mongocore/access'
require_relative 'mongocore/cache'
require_relative 'mongocore/filters'

