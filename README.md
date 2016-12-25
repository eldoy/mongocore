# MongoCore
MongoDB ORM implementation on top of the [MongoDB Ruby driver.](https://docs.mongodb.com/ruby-driver/master/quick-start/) Very fast and light weight.

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

# Delete
x.delete

# Count
c = Model.count
c = parent.models.featured.count

# Update
x.update(:duration => 60)

# Many associations
q = p.models.all
m = p.models.first
m = p.models.last

# Scopes
q = p.models.featured.all
q = p.models.featured.nested.all

# In your model
class Model
  include MongoCore::Document

  # Validations
  validate do
    errors[:duration] << 'duration must be greater than 0' if duration and duration < 1
    errors[:goal] << 'you need a higher goal' if goal and goal < 5
  end

  # Before and after, filters: :save, :update, :delete
  before :save, :setup

  def setup
    puts "Before save"
  end

  after(:delete) do
    puts "After delete"
  end
end
```

### Schema file
For keys, defaults, description, counters, associations, scopes and accessors, we use a schema file written in [YAML.](http://yaml.org)

Here's the Parent example model definition:
```yml

# The meta is information about your model
meta:
  name: parent
  type: document

keys:

  # Use the _id everywhere. The id can be used for whatever you want.
  # @desc: Describes the key, can be used for documentation.
  # @type: object_id, string, integer, float, boolean, time, hash, array, converts automatically (strict typing)
  # @default: the default value for the key when you call .new
  # @read: access level for read: all, user, dev, admin, super, app
  # @write: access level for write. Returns nil if no access, as on read

  _id:
    desc: Unique id
    type: object_id
    read: all
    write: app
  world:
    desc: Parent world
    type: string
    read: all
    write: user

  # If the key ends with _count, it will be used automatically when
  # you call .count on the model as an automatic caching mechanism
  models_count:
    desc: Models count
    type: integer
    default: 0
    read: all
    write: app

  # This field will be called when you write models.featured.count
  # If the field doesn't exist, the call will ask the database
  models_featured_count:
    desc: Models featured count
    type: integer
    default: 0
    read: all
    write: app

# Many relationships lets you do:
# Model.parents.all or model.parents.featured.all with scopes
many:
  models:
    dependent: destroy
```

Here is the Model class definition:

```yml
meta:
  name: model
  type: document
keys:
  _id:
    desc: Unique id
    type: object_id
    read: all
    write: app
  duration:
    desc: Model duration in days
    type: integer
    default: 60
    read: dev
    write: user
    tags:
    - badge
  expires_at:
    desc: Model expiry date
    type: time
    read: all
    write: dev
    tags:
    - badge
  location_data:
    desc: Model location data
    type: hash
    read: all
    write: user
  votes_count:
    desc: Votes count
    type: integer
    default: 0
    read: all
    write: dev
    tags:
    - badge

  # If the key ends with _id, it is treated as a foreign key,
  # and you can access it from the referencing model and set it too.
  # Example: model.parent, model.parent = parent
  parent_id:
    desc: Parent id
    type: object_id
    read: all
    write: dev

# Generate accessors (attr_accessor) for each key
accessor:
- submittable
- update_expires_at
- skip_before_save

# Define scopes that lets you do Models.featured.count
# Each scope has a name, and a set of triggers
scopes:

  # This will create a .featured scope, and add :duration => 60 to the query.
  featured:
    duration: 60
  nested:
    goal: 10

  # Any mongodb driver query is possible
  finished:
    duration: 60
    goal:
      $gt: 10
  active:
    params:
      - duration
    duration:
      $ne: duration

  # You can also pass parameters into the scope, as a lambda.
  ending:
    params:
     - user
    $or:
      - user_id: user.id
      - listener: user.id
      - listener: user.link
    deletors:
      $ne: user.id
```

### Contribute
Contributions and feedback are welcome! MIT Licensed.

Issues will be fixed, this library is actively maintained by [Fugroup Ltd.](http://www.fugroup.net) We are the creators of [CrowdfundHQ.](https://crowdfundhq.com)

Thanks!

```
@authors: Vidar
```
