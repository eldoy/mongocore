test 'Cache'

if MongoCore.cache

  @cache = (RequestStore[:cache] ||= {})
  @ids = (RequestStore[:ids] ||= Hash.new{|h, k| h[k] = []})

  @model = Model.first

  id = @model._id.to_s

  @model = Model.first

  @model = @model.reload
end
