test 'Save'

@model = Model.new

is @model.goal, nil

before_id = @model.id
@model.goal = 15

t = @model.save
is t.n, :gt => 0
is before_id.to_s, @model.id.to_s

test 'Reload'

@reload = @model.reload
is @reload.goal, 15

test 'Update'

@update = @model.update(:goal => 10)
is @model.goal, 10
is @update.n, :gt => 0

@model = @model.reload
is @model.goal, 10

@update = @model.update(:goal => nil)
is @model.goal, nil

test 'Delete'

@delete = @model.delete
is @delete.n, :gt => 0

# MAYBE: Model.insert, Model.update for insert_many and update_many
