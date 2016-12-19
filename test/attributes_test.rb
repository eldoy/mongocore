test 'Attributes'

@model = Model.new

# Defaults
a = @model.attributes
is a, :a? => Hash
is a[:id], @model.id
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
is @model.id, :a? => String
is @model._id, :a? => BSON::ObjectId

# Mechanics
@model.goal = 15
is @model.goal, 15

