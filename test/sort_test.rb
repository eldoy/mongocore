test 'Sort'

@models = Model.all
is @models, :a? => Array

@query = Model.find

@up = @query.sort(:duration => 1).all
@down = @query.sort(:duration => -1).all

is @up.size, @down.size

@one = @query.sort(:expires_at => 1).limit(2).all

is @one, :a? => Array
is @one.size, 2

@one = @query.sort(:expires_at => 1).limit(1).first
is @one, :a? => Model

@one = @query.limit(1).sort(:expires_at => 1).find(:duration => 60).first
is @one, :a? => Model

@models = Model.sort(:duration => 1).limit(2).all
is @models, :a? => Array
is @models.size, 2

@models = Model.limit(5).sort(:duration => 1).all
is @models, :a? => Array
is @models.size, 5
