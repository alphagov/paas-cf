class ElastiCacheUpdateFinder
  def initialize(elasticache_client)
    @elasticache_client = elasticache_client
  end

  def find_replication_groups_to_update
    replication_group_ids = {}

    marker = nil
    loop do
      response = @elasticache_client.describe_update_actions(
        service_update_status: %w[available],
        marker: marker,
      )

      marker = response.marker

      response
        .update_actions
        .select { |update| update.update_action_status == "not-applied" }
        .reject { |update| update.replication_group_id.nil? }
        .each do |update|
          replication_group_ids[update.service_update_name] ||= []
          replication_group_ids[update.service_update_name] << update.replication_group_id
        end

      break if marker.nil?
    end

    replication_group_ids
  end
end
