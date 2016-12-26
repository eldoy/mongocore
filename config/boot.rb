require 'bundler/setup'
Bundler.require(:default, :development)

MODE = ENV['RACK_ENV'] || 'development'

require 'yaml'

require './lib/mongocore.rb'

# Add settings here
Mongocore.schema = File.join(Dir.pwd, 'config', 'db', 'schema')

require './models/parent.rb'
require './models/model.rb'

# Logging verbosity
Mongo::Logger.logger.level = ::Logger::DEBUG
Mongo::Logger.logger.level = ::Logger::FATAL

# To make the driver log to a logfile instead:
# Mongo::Logger.logger       = ::Logger.new('mongo.log')
# Mongo::Logger.logger.level = ::Logger::INFO

# Connect to DB
Mongocore.db = Mongo::Client.new(['127.0.0.1:27017'], :database => "mongocore_#{MODE}")
