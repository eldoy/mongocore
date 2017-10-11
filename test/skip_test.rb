test 'Skip'

m = Model.find.skip(2).first

is m.id, :a? => String

m = Model.skip(2).first

is m.id, :a? => String
