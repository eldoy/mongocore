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

query.model.schema.ids(t)

is t[:_id][0], parent._id

t = {
  :parent_id => parent.id, :duration => 59
}

query.model.schema.ids(t)

is t[:parent_id], parent._id

t = {
  :$or => [{:parent_id => parent.id, :duration => 59}]
}

query.model.schema.ids(t)

is t[:$or][0][:parent_id], parent._id

t = {
  :_id => {:$in => [parent.id]}
}

query.model.schema.ids(t)

is t[:_id][:$in][0], parent._id

t = {
  :lists => [parent.id, parent.id]
}

query.model.schema.ids(t)

is t[:lists][0], parent._id

t = {
  :_id=> parent._id,
  :link=>nil,
  :goal=>nil,
  :duration=>60,
  :expires_at=>nil,
  :location_data=>{},
  :lists=>[model.id],
  :reminders_sent=>false,
  :votes_count=>0,
  :parent_id=>nil
}

puts t.inspect
query.model.schema.ids(t)
puts t.inspect
is t[:lists][0], model._id
