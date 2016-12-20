test 'Scopes'

is Model.scopes, :a? => Hash

is Model.featured, :a? => MongoCore::Query

@models = Model.featured.finished.all

is @models, :a? => Array

@model = Model.first

is @model, :a? => Model

@query = Model.featured.nested

is @query.query, :eq => {:duration => 60, :goal => 10}

@query = @query.find(:reminder_sent => false)

is @query.query, :eq => {:duration => 60, :goal => 10, :reminder_sent => false}
