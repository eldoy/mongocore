test 'Access'

@model = Model.new

is @model.duration, 60

s = Mongocore::Schema.new(Model)

a = Mongocore::Access.new(s)

is a.read?(:duration), :eq => true
is a.write?(:duration), :eq => true

a.set(:user)

is @model.duration, :eq => nil

@model.duration = 50

is @model.duration, :eq => nil

a.set(:app)

is @model.duration, :eq => 50

@model.duration = nil
is @model.duration, :eq => nil

a.set(:all)

m = (@model.duration = 20)

is m, :eq => 20
is @model.duration, :eq => 20
