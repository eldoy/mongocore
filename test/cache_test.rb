test 'Cache'

@parent = Parent.new
@parent.save

@model = Model.new(:parent_id => @parent._id)
@model.save

@model = Model.new
@model.parent_id = @parent.id
@model.save

@count = @parent.models.count
@parent.models_count = @count
@parent.save
@parent = @parent.reload

is @parent.models_count, 2

@query = @parent.models

is @parent.models.count, 2

# TODO: FIX HERE LOOKUP ASSOCIATIONS

@parent.models_count = 3
is @parent.models.count, 3

