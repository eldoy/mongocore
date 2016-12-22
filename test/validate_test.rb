test 'Validate'

@model = Model.new(:duration => -1)
is @model.duration, -1

if @model.respond_to?(:validate)
  @model.validate
  is @model.errors[:duration].include?('duration must be greater than 0'), :eq => true
end
