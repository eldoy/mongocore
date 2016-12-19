test 'Find'

# Query
@query = Model.find
is @query, :a? => MongoCore::Query

# Count
is Model.count, :a? => Integer
is Model.count, :gt => 0

# First
@model = @query.first
is @model, :a? => Model
is @model.duration, :gt => 0

# All
@models = @query.all
is @models, :a? => Array
is @models.size, :gt => 0

# Find
@models = Model.find(:duration => 60).all
is @models, :a? => Array
