Gem::Specification.new do |s|
  s.name        = 'mongo_core'
  s.version     = '0.0.2'
  s.date        = '2016-12-24'
  s.summary     = "MongoDB ORM implementation on top of the Ruby MongoDB driver"
  s.description = "Does validations, associations, scopes, filters, counter cache, request cache, and nested queries. Using a YAML schema file, which supports default values, data types, and security levels for each key."
  s.authors     = ["Fugroup Limited"]
  s.email       = 'mail@fugroup.net'
  s.files       = ["lib/mongo_core.rb"]
  s.add_runtime_dependency 'mongo', '~> 2.2'
  s.add_runtime_dependency 'bson_ext'
  s.add_runtime_dependency 'request_store'
  s.add_runtime_dependency 'activesupport'
  s.add_development_dependency 'futest'
  s.homepage    = 'https://github.com/fugroup/mongocore'
  s.license     = 'MIT'
end
