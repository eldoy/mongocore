test 'Validate'

@model = Model.new(:duration => -1)
is @model.duration, -1
is @model.valid?, :eq => true
# is @model.errors[:duration].include?('duration must be greater than 0'), :eq => true

