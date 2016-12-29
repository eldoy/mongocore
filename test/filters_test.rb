test 'Filters'

@model = Model.first

@model.run(:after, :delete)

@model.run(:before, :delete)
