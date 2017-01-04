class Model
  include Mongocore::Document

  # Just define a validate method and call it when needed
  # Use the errors hash to add your errors to it
  validate do
    errors[:duration] << 'duration must be greater than 0' if duration and duration < 1
    errors[:goal] << 'you need a higher goal' if goal and goal < 5
  end

  attr_accessor :list

  before :save do
    (@list ||= []) << 'before_save'
  end

  before :update do
    (@list ||= []) << 'before_update'
  end

  before :delete do
    (@list ||= []) << 'before_delete'
  end

  after :save do
    (@list ||= []) << 'after_save'
  end

  after :update do
    (@list ||= []) << 'after_update'
  end

  after :delete do
    (@list ||= []) << 'after_delete'
  end

  # Save, update, delete
  # before :delete, :hello
  # after(:delete){ puts "Hello" }

  # def hello
  #   puts "HELLO"
  # end
end
