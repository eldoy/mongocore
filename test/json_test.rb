test 'JSON'

m = Model.new

json = JSON.parse(m.to_json)

is json['id'], :a? => String
