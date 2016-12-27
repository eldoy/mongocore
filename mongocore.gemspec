Gem::Specification.new do |s|
  s.name        = 'mongocore'
  s.version     = '0.0.1'
  s.date        = '2016-12-26'
  s.summary     = "MongoDB ORM implementation on top of the Ruby MongoDB driver"
  s.description = "Does validations, associations, scopes, filters, counter cache, request cache, and nested queries. Using a YAML schema file, which supports default values, data types, and security levels for each key."
  s.authors     = ["Fugroup Limited"]
  s.email       = 'mail@fugroup.net'
  s.files       = ["lib/mongocore.rb"]
  s.add_runtime_dependency 'mongo', '~> 2.2'
  s.add_runtime_dependency 'bson_ext', '~> 0'
  s.add_runtime_dependency 'request_store', '~> 0'
  s.add_runtime_dependency 'activesupport', '~> 0'
  s.add_development_dependency 'futest', '~> 0'
  s.homepage    = 'https://github.com/fugroup/mongocore'
  s.license     = 'MIT'
end