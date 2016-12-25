test 'Features'

m = Model.new
m.duration = 59
m.save

is m.duration, 59

p = Parent.new(:house => 'Nice')
p.save
p = p.reload
is p.house, 'Nice'

m.parent = p
m.save

x = Model.last
is x._id.to_s, m._id.to_s

x.parent = p
x.save

d = p.models.all
f = p.models.first
l = p.models.last

