test 'Query'

@query = Mongocore::Query.new(Model)

test ' * objectid'

# Object ID converter
is @query.oid('test1234'), :a? => String
is @query.oid('58563c7a0aec085e6974346c'), :a? => BSON::ObjectId
is @query.oid(nil), :a? => BSON::ObjectId
is @query.oid(false), :a? => BSON::ObjectId
is @query.oid, :a? => BSON::ObjectId

test ' * cursor'

# Cursor
is @query.query, :eq => {}
is @query.colname, :models

@query2 = @query.find(:duration => 60)
is @query2.query, :eq => {:duration => 60}

@query2 = @query2.find(:duration => 50, :goal => {'$ne' => nil})
is @query2.query, :eq => {:duration => 50, :goal => {'$ne' => nil}}

test ' * first'

# First
@model = @query.first
is @model, :a? => Model

@model = @query.find(:duration => 60).first
is @model.duration, 60

# Count
is @query.count, :a? => Integer
is @query.count, :gt => 0

# Find all
@models = @query.find.all

is @models, :a? => Array
is @models.size, :gt => 0

test ' * json'

json = @query.to_json
is json, :a? => String
is JSON.parse(json), :a? => Array
