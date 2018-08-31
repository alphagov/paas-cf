module DeepFreeze
  def self.freeze(object)
    case object
    when Hash
      object.each { |_k, v| self.freeze(v) }
    when Array
      object.each { |v| self.freeze(v) }
    end
    object.freeze
  end
end
