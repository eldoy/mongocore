# Extensions for ruby classes

class Array

  # Holds the total number of pagination results
  attr_accessor :total

end

class String

  # Adding a to_bool method
  def to_bool
    return true if self =~ (/^(true|yes|t|y|[1-9]+)$/i)
    return false if self.empty? || self =~ (/^(false|no|n|f|0)$/i)

    raise ArgumentError.new %{invalid value: #{self}}
  end

end

module BSON
  class ObjectId

    # Override the to_json method
    def as_json(o = {})
      self.to_s
    end

  end
end
