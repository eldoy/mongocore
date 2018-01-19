test 'Errors'

model = Model.new
model.duration = 0

is model.errors, :a? => Hash
is model.valid?, false

is model.errors.keys.include?(:duration)

model = Model.new
model.duration = -1000
is model.save
is model.save(:validate => true), :eq => false

model.reload
is model.errors.empty?
is model.changes.empty?
