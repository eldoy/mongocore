#!/usr/bin/env ruby

require './config/boot'

include Futest::Helpers

# TODO: Move to Futest
def seed(*args, &block)
  case args[0]
  when :ask
    puts "Seed DB? y / n"; r = STDIN.gets.chomp
    yield if r.downcase != 'n'
  when :no
  else
    yield
  end
end

seed :no do
  puts "Deleting"
  Model.find.all.each{|m| m.delete}
  Parent.find.all.each{|p| p.delete}
  Model.new(:duration => 60).save
  Model.new(:goal => 10).save
end

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
  puts x.message
  e(x)
ensure
  puts Time.now - start
  if Mongocore.cache
    puts (RequestStore[:h] || 0).to_s + ' hit!'
    puts (RequestStore[:m] || 0).to_s + ' miss'
  end
end
