class Model
  include MongoCore::Document

  # Just define a validate method and call it when needed
  # Use the errors hash to add your errors to it
  def validate
    errors[:duration] << 'duration must be greater than 0' if duration and duration < 1
    errors[:goal] << 'you need a higher goal' if goal and goal < 5
  end

  # Save, update, delete
  # event(:delete){ puts "Hello" }

end
