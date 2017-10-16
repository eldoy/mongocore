test 'Tags'

@model = Model.new

is @model.attributes, Hash
size = @model.attributes.size

is @model.attributes(:badge).size, :lt => size

s = @model.attributes.size
j = @model.to_json

is j, String
is JSON.parse(j).size, s
