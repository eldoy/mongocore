test 'Associations'

# Many
@query = Parent.models
is @query, :a? => MongoCore::Query
@model = @query.first

# One
@parent = Parent.new
@parent.link = 'hello'
@parent.save

@model = Model.new(:parent_id => @parent.id)
is @model.parent_id, :a? => BSON::ObjectId
@model.save

is @model.parent, :a? => Parent
is @model.parent.link, 'hello'

@model.parent = @parent
is @model.parent_id, :eq => @parent._id
@p = @model.parent

is @p, :eq => @parent
