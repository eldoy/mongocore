test 'JSON'

model = Model.new
parent = Parent.new
model.parent = parent

is model.save

json = JSON.parse(model.to_json)

is json['id'], :a? => String
is json['parent_id'], :a? => String
is json['duration'], :a? => Integer

o = BSON::ObjectId.new

is o.to_json, "\"#{o.to_s}\""

t = {:id => o}

is t.to_json, "{\"id\":\"#{o.to_s}\"}"

t = {:id => [o, o]}

is t.to_json, "{\"id\":[\"#{o.to_s}\",\"#{o.to_s}\"]}"
