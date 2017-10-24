test 'JSON'

model = Model.new
parent = Parent.new
model.parent = parent

is model.save

json = JSON.parse(model.to_json)

is json['id'], :a? => String
is json['parent_id'], :a? => String
