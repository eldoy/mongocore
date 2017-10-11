test 'Projection'

m = Model.new(:duration => 54, :goal => 9)
m.save

is m.id, :a? => String

is m.duration, :a? => Integer

m2 = Model.fields(:goal => 0).last

is m2.duration, :a? => Integer

is m2.goal, nil
