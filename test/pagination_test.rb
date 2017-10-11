test 'Pagination'

models = Model.find.paginate

is models, :a? => Array

is models.total, :a? => Integer

m = Model.first

is models.first.id, m.id

is models.size, Mongocore.per_page

models = Model.find.paginate(:page => 2)

all = Model.limit(50).all

is all.size, 50

is models.size, Mongocore.per_page

is all[20].id, models.first.id

models = Model.find.paginate(:per_page => '50', :page => '1')

is models.size, 50

is models.last.id, all.last.id
