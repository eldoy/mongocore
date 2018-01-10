test 'Schema'

@model = Model.new

is @model._id, :a? => BSON::ObjectId
is @model.submittable, nil
is @model.duration, 60
is @model.reminders_sent, false

test ' * objectid'

@schema = Mongocore::Schema.new(Model)

# Object ID converter
is @schema.oid('test1234'), :a? => String
is @schema.oid('58563c7a0aec085e6974346c'), :a? => BSON::ObjectId
is @schema.oid(nil), :a? => BSON::ObjectId
is @schema.oid(false), :a? => BSON::ObjectId
is @schema.oid, :a? => BSON::ObjectId

test ' * time'

@model = Model.new
@model.expires_at = Time.now

is @model.expires_at, :a? => Time

@model.expires_at = '2018-01-10'

is @model.expires_at, :a? => Time

@model.expires_at = Date.today
is @model.expires_at, :a? => Time
