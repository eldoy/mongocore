test 'ID'

model = Model.new

is model._id, :a? => BSON::ObjectId

is model.id, :a? => String

is model.save

id = model.id

m = Model.first(:_id => id)

is m.id, id

m = Model.first(:id => id)

is m.id, id

m = Model.first(id)

is m.id, id

puts m.to_json
