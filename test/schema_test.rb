test 'Schema'
@model = Model.new

is @model._id, :a? => BSON::ObjectId
is @model.submittable, nil
is @model.duration, 60
is @model.reminders_sent, false
