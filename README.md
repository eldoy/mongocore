# Mongocore Ruby Database Driver
A new MongoDB ORM implementation on top of the [MongoDB Ruby driver.](https://docs.mongodb.com/ruby-driver/master/quick-start/) Very fast and light weight.

The perfect companion for Sinatra or other Rack-based web frameworks.

### Features
With Mongocore you can do:

* Insert, update and delete
* Finding, sorting, limit, skip, defaults
* Scopes, associations, validations, pagination
* Read and write access control for each key
* Request cache, counter cache, track changes
* Automatic timestamps, tagged keys, json

The schema is specified with a YAML file which supports default values, data types, and security levels for each key.

Please read [the source code](https://github.com/fugroup/mongocore/tree/master/lib/mongocore) to see how it works, it's fully commented and very small, only 8 files, and 360 lines of fully test driven code.

| Library                                | Files | Comment | Lines of code |
| -------------------------------------- | ----- | ------- | ------------- |
| [Mongoid](http://mongoid.com)          | 256   | 14371   | 10590         |
| [MongoMapper](http://mongomapper.com)  | 91    | 200     | 4070          |
| [Mongocore](http://mongocore.com)      | 8     | 230     | 360           |

<br>

The tests are written [using Futest,](https://github.com/fugroup/futest) try it out if you haven't, it makes testing so much fun.

### Installation
```
gem install mongocore
```
or add to your Gemfile.

Then in your model:
```ruby
class Model
  include Mongocore::Document
end
```

### Settings
Mongocore has a few built in settings you can easily toggle:
```ruby
# Schema path is $app_root/config/db/schema/:model.yml
# The yml files should have singular names
Mongocore.schema = File.join(Dir.pwd, 'config', 'db', 'schema')

# The cache stores documents in memory to avoid db round trips
Mongocore.cache = true

# The access enables the read / write access levels for the keys
Mongocore.access = true

# Enable timestamps, auto-save created_at and updated_at keys
Mongocore.timestamps = true

# Pagination results per page
Mogocore.per_page = 20

# Enable debug to see caching information and help
Mongocore.debug = false
```

### Usage

```ruby
# Set up connection to database engine
Mongocore.db = Mongo::Client.new(['127.0.0.1:27017'], :database => "mongocore_#{ENV['RACK_ENV']}")

# Create a new document
m = Model.new
m.duration = 59
m.save

# Create another document
p = Parent.new(:house => 'Nice')
p.save

# Reload the model attributes from the database
p.reload

# Add the parent to the model
m.parent = p
m.save

# Finding
query = Model.find
query = Model.where # Alias

# Query doesn't get executed until you call all, count, last or first
m = query.all
a = query.featured.all
c = query.count
l = query.last
f = query.first

# All
m = Model.find.all

# Pagination returns an array
m = Model.find.paginate
m = Model.find.paginate(:per_page => 10, :page => 5)
m.total # => Total number of results

# Use each to fetch one by one
Model.each do |m|
  puts m
end

# Works with finds, scopes and associations
Model.find(:duration => 50).each{|m| puts m}

# All of these can be used:
# https://docs.mongodb.com/manual/reference/operator/query-comparison
m = Model.find(:house => {:$ne => nil, :$eq => 'Nice'}).last

# Sorting, use -1 for descending, 1 for ascending
m = Model.find({:duration => {:$gt => 40}}, {}, :sort => {:duration => -1}).all
m = p.models.find(:duration => 10).sort(:duration => -1).first

# Limit, pass as third option to find or chain, up to you
p = Parent.find.sort(:duration => 1).limit(5).all
p = Parent.limit(1).last
m = p.models.find({}, {}, :sort => {:goal => 1}, :limit => 1).first
m = Model.sort(:goal => 1, :duration => -1).limit(10).all

# First
m = Model.find(:_id => object_id).first
m = Model.find(object_id).first
m = Model.find(string).first
m = Model.find(:duration => 60, :goal => {:$gt => 0}).first

# Last
m = Model.last
m = p.models.last

# Count
c = Model.count
c = p.models.featured.count

# Skip
m = Model.find.skip(2).first

# Tagged keys for attributes and to_json
m = Model.first
m.attributes             # => All attributes
m.attributes(:badge)     # => Attributes with the badge tag only
m.to_json                # => All attributes as json
m.to_json(:badge, :test) # => Pass multiple tags if needed

# Track changes
m.duration = 33
m.changed?
m.duration_changed?
m.duration_was
m.changes
m.saved?
m.persisted? # Alias for saved?
m.unsaved?
m.new_record? # Alias for unsaved?

# Validate
m.valid?
m.errors.any?
m.errors

# Update
m.update(:duration => 60)

# Delete
m.delete

# Many associations
q = p.models.all
m = p.models.first
m = p.models.last

# Scopes
q = p.models.featured.all
q = p.models.featured.nested.all
m = Model.featured.first

# In your model
class Model
  include Mongocore::Document

  # Validations will be run if you pass model.save(:validate => true)
  # You can run them manually by calling model.valid?
  # You can have multiple validate blocks if you want to
  validate do
    # The errors hash can be used to collect error messages.
    errors[:duration] << 'duration must be greater than 0' if duration and duration < 1
    errors[:goal] << 'you need a higher goal' if goal and goal < 5
  end

  # Before and after, filters: :save, :update, :delete
  # You can have multiple blocks for each filter if needed
  before :save, :setup

  def setup
    puts "Before save"
  end

  after :delete do
    puts "After delete"
  end
end

# Use pure Ruby driver, returns BSON::Document objects
Mongocore.db[:models].find.to_a
Mongocore.db[:models].find({:_id => m._id}).first

# Indexing
Mongocore.db[:models].indexes.create_one({:key => 1})
Mongocore.db[:models].indexes.create_one({:key => 1}, :unique => true)
```

### Schema and models
Each model defined using a [YAML.](http://yaml.org) schema file. This is where you define keys, defaults, description, counters, associations, access, tags, scopes and accessors.

The default schema file location is `APP_ROOT/config/db/schema/*.yml`, so if you have a model called Parent, create a yml file called parent.yml.

You can change the shema file location like this:
```ruby
Mongocore.schema = File.join(Dir.pwd, 'your', 'schema', 'path')
```

#### Parent example schema, has many Models
```yml

# The meta is information about your model
meta:
  name: parent
  type: document

keys:

  # Define the _id field for all your models. The id field (without _)
  # is an alias to _id, but always returns a string instead of a BSON::ObjectId
  # @desc: Describes the key, can be used for documentation.
  # @type: object_id, string, integer, float, boolean, time, hash, array
  # @default: the default value for the key when you call .new
  # @read: access level for read: all, user, dev, admin, super, app
  # @write: access level for write. Returns nil if no access, as on read

  # Object ID, usually added for each model
  _id:
    desc: Unique id
    type: object_id
    read: all
    write: app

  # String key
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

  # This field will be returned when you write models.featured.count
  # Remember to create an after filter to keep it updated
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


#### Model example schema, belongs to Parent

```yml
meta:
  name: model
  type: document

keys:
  # Object ID
  _id:
    desc: Unique id
    type: object_id
    read: all
    write: app

  # Integer key with default
  duration:
    desc: Model duration in days
    type: integer
    default: 60
    read: dev
    write: user
    # Add tags for keys for use with attributes and to_json
    tags:
    - badge

  # Time key
  expires_at:
    desc: Model expiry date
    type: time
    read: all
    write: dev
    # Multiple tags possible: to_json(:badge, :campaigns)
    tags:
    - badge
    - campaigns

  # Hash key
  location_data:
    desc: Model location data
    type: hash
    read: all
    write: user

  # Counter key
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

`@authors: Vidar`
