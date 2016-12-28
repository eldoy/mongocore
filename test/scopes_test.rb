test 'Scopes'

is Model.schema.scopes, :a? => Hash

is Model.featured, :a? => Mongocore::Query

@models = Model.featured.finished.nested.all

is @models, :a? => Array

@model = Model.first

is @model, :a? => Model

@query = Model.featured.nested

is @query.query, :eq => {:duration => 60, :goal => 10}

@query = @query.find(:reminder_sent => false)

is @query.query, :eq => {:duration => 60, :goal => 10, :reminder_sent => false}

is @query.all, :a? => Array

@parent = Parent.new
@parent.save

@model = Model.new(:parent_id => @parent._id)
@model.save

@model = Model.new
@model.parent_id = @parent._id
@model.save

@models = @parent.models.all
is @models, :a? => Array
is @models.count, 2
is @models.first, :a? => Model
