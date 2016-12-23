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
or add to your Gemfile.

Then in your model:
```ruby
class Model
  include MongoCore::Document
end
```

### Status
CRUD, querying, scopes, associations, validations, sorting, limit, cache, works.

Working on access control, dirty attributes and docs.

Send us a message if you want to contribute.

12/22/16
