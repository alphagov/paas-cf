# rubocop:disable Layout/CaseIndentation
# rubocop:disable Layout/EndAlignment

def parse_integer_quantity(value)
  return value.to_i if value.to_i == value

  if value.is_a? String
    m = /^(?<integer>\d+)(?<multiplier>[KMGT])?$/.match(value.upcase)

    unless m.nil?
      # assuming we're talking to the cloud controller, K/M/etc seem to
      # usually mean the binary ("IEC") multiplier as it uses the
      # palm_civet gem to covert these.
      return m[:integer].to_i * (1024**(case m[:multiplier]
        when nil
          0
        when "K"
          1
        when "M"
          2
        when "G"
          3
        when "T"
          4
        else
          abort "unhandled multiplier #{m[:multiplier]}"
      end))
    end
  end
  abort "Cannot parse #{value} as a simple integer quantity" if m.nil?
end

# rubocop:enable Layout/EndAlignment
# rubocop:enable Layout/CaseIndentation
