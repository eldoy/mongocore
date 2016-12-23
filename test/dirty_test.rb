test 'Dirty'

@model = Model.new

is @model.duration, 60

@model.duration = "60"

is @model.changed?, :eq => false
is @model.duration_changed?, :eq => false

@model.duration = 40
is @model.changed?, :eq => true
is @model.duration_changed?, :eq => true
is @model.duration_was, :eq => 60
