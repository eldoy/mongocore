class Model
  include Mongocore::Document

  # Just define a validate method and call it when needed
  # Use the errors hash to add your errors to it
  validate do
    errors[:duration] << 'duration must be greater than 0' if duration and duration < 1
    errors[:goal] << 'you need a higher goal' if goal and goal < 5
  end

  # Save, update, delete
  # before :delete, :hello
  # after(:delete){ puts "Hello" }

  # def hello
  #   puts "HELLO"
  # end
end
