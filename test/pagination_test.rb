test 'Pagination'

models = Model.find.paginate

is models, :a? => Array

is models.total, :a? => Integer

m = Model.first

is models.first.id, m.id

is models.size, Mongocore.per_page

models = Model.find.paginate(:page => 2)

all = Model.limit(2).all

is all.size, 2

is models.size, :lte => Mongocore.per_page

models = Model.find.paginate(:per_page => '2', :page => '1')

is models.size, 2

is models.last.id, all.last.id

models = Model.paginate
is models, :a? => Array

models = Model.paginate(:per_page => '2', :page => '1')
is models.size, 2

is models.last.id, all.last.id
