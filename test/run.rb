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
    'filters',
    'counter',
    'cache',
    'dirty',
    'access',
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
