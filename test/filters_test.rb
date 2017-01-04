test 'Filters'

@model = Model.first

test '* run'

@model.run(:before, :save)
@model.run(:before, :update)
@model.run(:before, :delete)

@model.run(:after, :save)
@model.run(:after, :update)
@model.run(:after, :delete)

is @model.list.size, 6


test '* save'

@model = Model.new

@model.save

is @model.saved?, true
is @model.list.include?('before_save')
is @model.list.include?('after_save')

@model.list = []

@model.update
is @model.saved?, true
is @model.list.include?('before_update')
is @model.list.include?('after_update')

@model.list = []

@model.delete
is @model.saved?, false
is @model.list.include?('before_delete')
is @model.list.include?('after_delete')
