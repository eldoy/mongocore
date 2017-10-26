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
