test 'Dirty'

@model = Model.new

is @model.duration, 60

@model.duration = "60"

is @model.duration, :eq => 60
is @model.changed?, :eq => false
is @model.duration_changed?, :eq => false

@model.duration = 40
is @model.changed?, :eq => true
is @model.duration_changed?, :eq => true
is @model.duration_was, :eq => 60

is @model.save
@model.reload

is @model.changes.empty?, :eq => true
is @model.duration, :eq => 40
@model.duration = 50

is @model.changed?, :eq => true
is @model.duration_changed?, :eq => true
is @model.duration_was, :eq => 40

@model.auth = 'Hello'
is @model.save
is @model.changed?, :eq => false
is @model.changes.empty?, :eq => true
is @model.auth_changed?, :eq => false
is @model.auth_was, :eq => 'Hello'

@model.reload
is @model.changes.empty?, :eq => true

is @model.auth, 'Hello'
@model.auth = 'Hello2'
is @model.changed?, :eq => true
is @model.auth_changed?, :eq => true
is @model.auth_was, :eq => 'Hello'

@model = Model.last
is @model.auth, 'Hello'
is @model.original[:auth], 'Hello'
