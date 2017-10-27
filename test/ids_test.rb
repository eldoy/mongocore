test 'Ids'

query = Mongocore::Query.new(Model)

model = Model.new
parent = Parent.new
model.parent = parent
model.save
parent.save

t = {
  :id => [parent.id]
}

query.ids(t)

is t[:id][0], parent._id

t = {
  :parent_id => parent.id, :duration => 59
}

query.ids(t)

is t[:parent_id], parent._id

t = {
  :$or => [{:parent_id => parent.id, :duration => 59}]
}

query.ids(t)

is t[:$or][0][:parent_id], parent._id

t = {
  :_id => {:$in => [parent.id]}
}

query.ids(t)

is t[:_id][:$in][0], parent._id
