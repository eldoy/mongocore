test 'Insert'

@model = Model.insert(:duration => 50)
is @model.saved?, true
is @model.id, :a? => String

@model2 = Model.first(@model.id)
is @model2.id, @model.id


@model = Model.create(:duration => 50)
is @model.saved?, true
is @model.id, :a? => String

@model2 = Model.first(@model.id)
is @model2.id, @model.id
