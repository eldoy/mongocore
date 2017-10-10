test 'Errors'

model = Model.new
model.duration = 0

is model.errors, :a? => Hash
is model.valid?, false

is model.errors.keys.include?(:duration)
