# MongoCore
MongoDB ORM implementation on top of the [MongoDB Ruby driver.](https://docs.mongodb.com/ruby-driver/master/quick-start/) Very fast and light weight, few dependencies.

The perfect companion for Sinatra or other Rack-based web frameworks.

### Features
With MongoCore you can do:

* Saving, updating, deleting
* Querying, sorting, limit, defaults
* Scopes, associations, validations
* Read and write access control for each key
* Request cache, counter cache, track changes

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

### Usage

```ruby
# Create a new document
m = Model.new
m.duration = 59
m.save

# Create another document
p = Parent.new(:house => 'Nice')
p.save
p = p.reload

# Add the parent to the model
m.parent = p
m.save

# Find the last model
x = Model.last
x.parent = p
x.save

# Many associations
q = p.models.all
m = p.models.first
m = p.models.last
```

### Contribute

*MIT Licensed, contributions are welcome!*

[http://www.fugroup.net](http://www.fugroup.net)
