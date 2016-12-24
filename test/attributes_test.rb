test 'Attributes'

@model = Model.new

# Defaults
a = @model.attributes
is a, :a? => Hash
is a[:_id], @model._id
is a[:submittable], nil
is a[:duration], 60
is a[:reminders_sent], false

# Passing attributes
@model = Model.new(:duration => 2000, :goal => -10)
is @model.duration, 2000
is @model.attributes[:duration], 2000
is @model.goal, -10
is @model.attributes[:goal], -10

# Static typing
@model.duration = "60"
is @model.duration, 60

# id should be string, _id should be BSON::ObjectId
is @model._id, :a? => BSON::ObjectId

# Mechanics
@model.goal = 15
is @model.goal, 15

@model = Model.new

is @model.saved?, :eq => false
is @model.unsaved?, :eq => true

@model.save
is @model.saved?, :eq => true

@model = Model.new
is @model.unsaved?, :eq => true

@model = Model.first
is @model.saved?, :eq => true

@model.duration = Time.now.to_i
is @model.changed?, :eq => true
@model.save
is @model.changed?, :eq => true
is @model.saved?, :eq => true

test 'attributes'
@model = Model.new

is @model.attributes[:duration], 60
@model.attributes = {:duration => 50}

is @model.duration, 50






