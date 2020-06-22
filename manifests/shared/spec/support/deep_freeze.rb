module DeepFreeze
  def self.freeze(object)
    case object
    when Hash
      object.each { |_k, v| freeze(v) }
    when Array
      object.each { |v| freeze(v) }
    end
    object.freeze
  end
end
