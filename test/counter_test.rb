test 'Counter'

@parent = Parent.new
@parent.save

@model = Model.new
@model.parent = @parent
@model.save

@model = Model.new
@model.parent = @parent
@model.save

@count = @parent.models.all.size
is @count, 2

@parent.models_count = @count
@parent.save

is @parent.models_count, 2
is @parent.models.count, 2

@parent.models_count = 3
is @parent.models.count, 3

c = @parent.models.featured.count
is c, :a? => Integer
