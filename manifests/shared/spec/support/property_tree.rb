require "yaml"

class PropertyTree
  def initialize(tree)
    @tree = tree
  end

  def self.load_yaml(yaml_string)
    PropertyTree.new(YAML.safe_load(yaml_string))
  end

  def recursive_get(tree, key_array)
    return tree if key_array.empty?

    current_key, *next_keys = key_array

    next_level = case tree
                 when Hash
                   tree[current_key]
                 when Array
                   if current_key =~ /\A[-+]?\d+\z/ # If the key is an int, access by index
                     tree[current_key.to_i]
                   else # if not, search for a element with `name: current_key`
                     tree.select { |x| x.is_a?(Hash) && x["name"] == current_key }.first
                   end
                 end
    unless next_level.nil?
      recursive_get(next_level, next_keys)
    end
  end

  def get(key)
    key_array = key.split(".")
    recursive_get(@tree, key_array)
  end

  def [](key)
    get(key)
  end

  def fetch(key, default_value = nil)
    ret = get(key)
    if ret.nil?
      if default_value.nil?
        raise KeyError, key
      else
        return default_value
      end
    end
    ret
  end

  # Recursive perform an inject as in Ennumerable::inject, but
  # passing the path of the element with the syntax used
  # in BOSH opsfiles.
  def recursive_inject(acum, yaml_value, path, &block)
    x = yaml_value

    case x
    when Hash
      x.inject(acum) do |acum2, (key, x2)|
        recursive_inject(acum2, x2, "#{path}/#{key}", &block)
      end
    when Array
      x.each_with_index.inject(acum) do |acum2, (x2, index)|
        new_path = if x2.is_a?(Hash) && x2.key?("name")
                     "#{path}/name=#{x2['name']}"
                   else
                     "#{path}/#{index}"
                   end
        recursive_inject(acum2, x2, new_path, &block)
      end
    else
      yield(acum, x, path)
    end
  end

  def inject(acum, &block)
    recursive_inject(acum, @tree, "", &block)
  end
end
