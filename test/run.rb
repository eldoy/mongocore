#!/usr/bin/env ruby

require './config/boot'

include Futest::Helpers

# Load tests. Comment out the ones you don't want to run.
begin
  start = Time.now
  [
    'connection',
    'query',
    'schema',
    'attributes',
    'save',
    'find',
    'scopes',
    'associations',
    'sort',
    'validate',
    'events',
    'counter',
    'cache',
    'dirty',
    'access'
  ].each{|t| require_relative "#{t}_test"}
rescue => x
  puts x.message
  e(x)
ensure
  puts Time.now - start
  puts RequestStore[:h].to_s + ' hit!'
  puts RequestStore[:m].to_s + ' miss'
end

# Info on MongoDB Driver
# https://docs.mongodb.com/ruby-driver/master/quick-start/
# http://zetcode.com/db/mongodbruby/
# http://recipes.sinatrarb.com/p/databases/mongo
# https://github.com/steveren/ruby-driver-sample-app/blob/master/lib/neighborhood.rb

# Indexing
# $db[:profiles].indexes.create_one({:key => 1}, :unique => true)
