test 'Access'

model = Mongocore::Access.role(:user) do
  model = Model.new
  is model.duration, nil

  model.expires_at = Time.now
  is model.expires_at, nil

  model
end

is model, :a? => Model

model = Mongocore::Access.role(:dev) do
  model = Model.new
  model.save
  is model.duration, 60
  model
end

is model, :a? => Model
