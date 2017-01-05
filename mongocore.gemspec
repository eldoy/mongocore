Gem::Specification.new do |s|
  s.name        = 'mongocore'
  s.version     = '0.1.1'
  s.date        = '2017-01-05'
  s.summary     = "MongoDB ORM implementation on top of the Ruby MongoDB driver"
  s.description = "Does validations, associations, scopes, filters, counter cache, request cache, and nested queries. Using a YAML schema file, which supports default values, data types, and security levels for each key."
  s.authors     = ["Fugroup Limited"]
  s.email       = 'mail@fugroup.net'

  s.add_runtime_dependency 'mongo', '~> 2.2'
  s.add_runtime_dependency 'request_store', '>= 0'
  s.add_runtime_dependency 'activesupport', '>= 0'
  s.add_development_dependency 'futest', '>= 0'

  s.homepage    = 'https://github.com/fugroup/mongocore'
  s.license     = 'MIT'

  s.require_paths = ['lib']
  s.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
end
