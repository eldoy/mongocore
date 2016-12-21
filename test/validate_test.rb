test 'Validate'

@model = Model.new(:duration => -1)
is @model.duration, -1

@model.validate # if @model.respond_to?(:validate)

puts @model.errors.inspect

is @model.errors[:duration].include?('duration must be greater than 0'), :eq => true








