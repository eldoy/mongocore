test 'Each'

Model.each do |r|
  is r.duration
end

Model.each_with_index do |r, n|
  is r.duration
  is n, :a? => Integer
end

Model.each_with_object('test') do |r, o|
  is r.duration
  is o, 'test'
end

q = Model.map do |r|
  is r.duration
  r
end
is q, :a? => Array

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

count = 0
result = parent.models.map do |r|
  count += 1
  is r.duration, 999
  r.duration
end

is result, :a? => Array

count = 0
parent.models.each_with_index do |r, n|
  count += n
  is r.duration, 999
end

is count > 0

parent.models.each_with_object('test') do |r, s|
  is s, 'test'
  is r.duration, 999
end
