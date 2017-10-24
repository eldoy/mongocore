test 'Each'

Model.each do |r|
  is r.duration
end

parent = Parent.new
is parent.save

model = Model.new
model.parent = parent
model.duration = 999
is model.save

model2 = Model.new
model2.duration = 999
model2.parent = parent
is model2.save

count = 0
parent.models.each do |r|
  count += 1
  is r.duration, 999
end

is count, 2
