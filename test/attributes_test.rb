test 'Attributes'

@model = Model.first
is @model.to_json, :a? => String
is @model.to_s, :a? => String

@model = Model.new

# Defaults
a = @model.attributes
is a, :a? => Hash
is a[:_id], @model._id
is a[:_id].to_s, @model.id
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

@model = Model.new
@model.duration = Time.now.to_i
is @model.changed?, :eq => true
@model.save

is @model.changed?, :eq => false
is @model.saved?, :eq => true

test 'attributes'
@model = Model.new

is @model.attributes[:duration], 60
@model.attributes = {:duration => 50}

is @model.duration, 50

@parent = Parent.new
is @parent.save

@model = Model.new
@model.parent = @parent
is @model.save
is @model.parent.id, @parent.id
is @parent.models.all.size, 1

@model.attributes = {:parent_id => @parent.id}
@model.save

is @parent.models.all.size, 1

test 'boolean'

@model = Model.new
@model.reminders_sent = false
@model.save

@model = @model.reload
is @model.reminders_sent, false

@model.reminders_sent = 'false'
@model.save

@model = @model.reload
is @model.reminders_sent, false

@model.reminders_sent = 'true'
@model.save

@model = @model.reload
is @model.reminders_sent, true

@model.reminders_sent = '0'
@model.save

@model = @model.reload
is @model.reminders_sent, false

@model.reminders_sent = 'n'
@model.save

@model = @model.reload
is @model.reminders_sent, false

@model.reminders_sent = 'no'
@model.save

@model = @model.reload
is @model.reminders_sent, false

@model.reminders_sent = 'true'
@model.save

@model = @model.reload
is @model.reminders_sent, true

@model.reminders_sent = '1'
@model.save

@model = @model.reload
is @model.reminders_sent, true

@model.reminders_sent = 'y'
@model.save

@model = @model.reload
is @model.reminders_sent, true

@model.reminders_sent = 'yes'
@model.save

@model = @model.reload
is @model.reminders_sent, true

@model.reminders_sent = 1
@model.save

@model = @model.reload
is @model.reminders_sent, true

@model.reminders_sent = 2
@model.save

@model = @model.reload
is @model.reminders_sent, true

@model = Model.new
@model.save

is @model.reload.id

bson = Mongocore.db[:models].find(:_id => @model._id).first
is bson[:id], nil
is bson[:_id]

parent = Parent.new

@model.attributes = {
  :lists => [parent.id]
}

is @model.attributes[:lists][0], parent._id

@model.lists = []

is @model.lists.empty?

@model.lists = [parent.id]

is @model.attributes[:lists][0], parent._id

is @model.lists[0], parent._id

@model.location_data = {:hello => parent.id}

is @model.location_data[:hello], parent._id

@model.duration = nil
@model.write('duration', 50)
is @model.duration, 50
is @model.read('duration'), 50
is @model.read(:duration), 50
is @model.read!('duration'), 50
is @model.read!(:duration), 50

@model.duration = nil
@model.write(:duration, 50)
is @model.duration, 50
is @model.read('duration'), 50
is @model.read(:duration), 50
is @model.read!('duration'), 50
is @model.read!(:duration), 50
