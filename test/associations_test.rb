test 'Associations'

@parent = Parent.new
ts = "hello#{Time.now.to_s}"
@parent.link = ts
@parent.save

@model = Model.new(:parent_id => @parent._id)
is @model.parent_id, :a? => BSON::ObjectId
@model.save

is @model.parent, :a? => Parent
is @model.parent.link, ts

@model.parent = @parent
is @model.parent_id, :eq => @parent._id
@p = @model.parent

is @p, :eq => @parent

@models = @parent.models.featured.all

is @models, :a? => Array
is @models.first, :a? => Model
