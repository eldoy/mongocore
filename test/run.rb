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
    'each',
    'operators',
    'tags',
    'save',
    'insert',
    'find',
    'scopes',
    'associations',
    'sort',
    'validate',
    'filters',
    'timestamps',
    'counter',
    'cache',
    'dirty',
    'access',
    'errors',
    'id',
    'json',
    'projection',
    'skip',
    'pagination',
    'features'
  ].each{|t| require_relative "#{t}_test"}
rescue => x
  err(x, :vv)
ensure
  puts Time.now - start
  if Mongocore.cache
    puts (RequestStore[:h] || 0).to_s + ' hit!'
    puts (RequestStore[:m] || 0).to_s + ' miss'
  end
end
