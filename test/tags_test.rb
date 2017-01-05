test 'Tags'

@model = Model.new

is @model.attributes, Hash
size = @model.attributes.size

is @model.attributes(:badge).size, :lt => size

s = @model.attributes.size
j = @model.to_json
is j, String
is JSON.parse(j).size, s

j = @model.to_json(:badge)
is j, String
p = JSON.parse(j)

is p.size, :lt => s
is s, @model.attributes.size

is p['location_data'], nil
is p['duration'], 60
