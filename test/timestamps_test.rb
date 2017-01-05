test 'Timestamps'

@model = Model.new
is @model.created_at, nil
is @model.updated_at, nil

@model.save

is @model.created_at, :a? => Time
is @model.updated_at, :a? => Time

@model.reload

is @model.created_at, :a? => Time
is @model.updated_at, :a? => Time

t1 = @model.created_at
t2 = @model.updated_at

@model.update

is @model.created_at, t1
is @model.updated_at, :gt => t2

@model.reload

is @model.created_at, t1
is @model.updated_at, :gt => t2

is @model.reload, Model
