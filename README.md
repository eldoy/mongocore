# MongoCore
MongoDB ORM implementation on top of the Ruby MongoDB driver. Very fast and light weight.

### Features
Thin layer on top of the [MongoDB Ruby driver.](https://docs.mongodb.com/ruby-driver/master/quick-start/)

Does validations, associations, scopes, filters, counter cache, request cache, and nested queries.

We're using a YAML schema file, which supports default values, data types, and security levels for each key.

### Installation
```
gem install mongo_core
```

Then in your model:
```ruby
class Model
  include MongoCore::Document
end
```

### Status
CRUD, querying, scopes and associations works.

Working on validations, sorting, dirty, counters, limit and cache.

Send us a message if you want to contribute.
