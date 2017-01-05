class Parent
  include Mongocore::Document

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

end
