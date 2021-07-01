require "yaml"

manifest = YAML.safe_load(STDIN.read)

zones = ARGV
puts YAML.dump(
  manifest.dig("instance_groups")
   .map do |g|
     {
       "type" => "replace",
       "path" => "/instance_groups/name=#{g['name']}/azs",
       "value" => (g["azs"] - zones),
     }
   end,
)
