test 'Access'

RequestStore.store[:access] = nil

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

@model = Model.new
is @model.save

is @model.duration, 60

RequestStore.store[:access] = nil

Model.role(:all)

is @model.duration, nil

is @model.attributes[:duration], nil

@model.duration = 60

is @model.duration, nil

@model2 = Model.new

is @model2.save
is @model2.duration, nil

# Reset before running next test
RequestStore.store[:access] = nil
