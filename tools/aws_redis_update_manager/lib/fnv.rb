def fnv_base32_encode(inp)
  alphabet = "abcdefghijklmnopqrstuvwxyz234567"

  remainder = inp.bytesize.modulo 5
  padding = "\0" * (5 - remainder)
  inp += padding

  inp.gsub!(/.{5}/mn) do |s|
    n32, i8 = s.unpack("NC")
    n32 = (n32 << 8) | i8

    8.times.reduce "" do |accumulator|
      n32, i8 = n32.divmod 32
      chr = alphabet[i8]
      "#{chr}#{accumulator}"
    end
  end

  first_12_chars = inp[0..12]
  first_12_chars
end

def fnv(input)
  offset = 0xcbf29ce484222325
  prime = 1_099_511_628_211
  mask = 18_446_744_073_709_551_615

  hash = offset

  input.each_byte do |b|
    hash ^= b
    hash *= prime
    hash &= mask
  end

  packed = [hash.to_s(16)].pack("H*")
  fnv_base32_encode(packed)
end
