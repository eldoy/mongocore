test 'Operators'

@parent = Parent.new
@parent.save
@model = Model.new
@model.parent = @parent
@model.save

is @model.duration, 60

@model = Model.find(:duration => 60).first
is @model.duration, 60

@model = Model.find(:duration => {:$eq => 60}).first
is @model.duration, 60

@model = Model.find(:duration => {:$gt => 60}).first
is @model.duration, :gt => 60

@model = Model.find(:duration => {:$ne => 60}).first
is @model.duration, :ne => 60

@model = Model.find(:parent_id => @parent.id).first
is @model.parent_id.to_s, @parent.id

@model = Model.find(:parent_id => {:$eq => @parent._id}).first

is @model.parent_id.to_s, @parent.id

@model = Model.find(:parent_id => {:$eq => @parent.id}).first
is @model.parent_id.to_s, @parent.id
