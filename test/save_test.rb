test 'Save'

@model = Model.new

is @model.goal, nil

before_id = @model._id
@model.goal = 15

t = @model.save
is t, true
is before_id.to_s, @model._id.to_s

model = Model.new

model.duration = -1
t = model.save(:validate => true)
is t, false

test 'reload'

@model.reload
is @model.goal, 15

test 'update'

@update = @model.update(:goal => 10)
is @model.goal, 10
is @update, true

@model = @model.reload
is @model.goal, 10

@update = @model.update(:goal => nil)
is @model.goal, nil

test 'delete'

@delete = @model.delete
is @delete.n, :gt => 0


test 'upsert'

@model = Model.new
@model.duration = 40
id = @model._id.to_s
@model.save

is @model._id.to_s, id
