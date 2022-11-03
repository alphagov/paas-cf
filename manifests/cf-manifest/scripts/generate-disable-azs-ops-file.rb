require "yaml"

manifest = YAML.safe_load($stdin.read)

zones = ARGV
puts YAML.dump(
  manifest["instance_groups"]
   .map do |g|
     {
       "type" => "replace",
       "path" => "/instance_groups/name=#{g['name']}/azs",
       "value" => (g["azs"] - zones),
     }
   end,
)
