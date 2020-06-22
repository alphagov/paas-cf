require "ostruct"

RSpec.describe ElastiCacheUpdateFinder do
  def self.when_elasticache_returns(update_actions)
    let(:elasticache_client) do
      c = Class.new do
        def initialize(update_actions)
          @update_actions = update_actions
        end

        def describe_update_actions(*)
          OpenStruct.new(
            marker: nil,
            update_actions: @update_actions.map { |h| OpenStruct.new(h) },
          )
        end
      end
      c.new(update_actions)
    end
  end

  context "with no update actions available" do
    when_elasticache_returns []

    it "finds no instances to update" do
      finder = ElastiCacheUpdateFinder.new(elasticache_client)
      expect(finder.find_replication_groups_to_update).to have_attributes(length: 0)
    end
  end

  context "with updates only available for cache clusters" do
    when_elasticache_returns [
      {
        cache_cluster_id: "cache-cluster-id-123",
        update_action_status: "not-applied",
      },
    ]

    it "finds no instances to update" do
      finder = ElastiCacheUpdateFinder.new(elasticache_client)
      expect(finder.find_replication_groups_to_update).to have_attributes(length: 0)
    end
  end

  context "with a single update available" do
    when_elasticache_returns [
      {
        service_update_name: "an-update-to-apply",
        replication_group_id: "replication-group-id",
        update_action_status: "not-applied",
      },
    ]

    it "finds a single instance to update" do
      finder = ElastiCacheUpdateFinder.new(elasticache_client)
      expect(finder.find_replication_groups_to_update).to eq(
        "an-update-to-apply" => ["replication-group-id"],
      )
    end
  end

  context "with a multiple updates available" do
    when_elasticache_returns [
      {
        service_update_name: "an-update-to-apply",
        replication_group_id: "replication-group-id",
        update_action_status: "not-applied",
      },
      {
        service_update_name: "another-update-to-apply",
        replication_group_id: "another-replication-group-id",
        update_action_status: "not-applied",
      },
    ]

    it "finds a both instance to update" do
      finder = ElastiCacheUpdateFinder.new(elasticache_client)
      expect(finder.find_replication_groups_to_update).to eq(
        "an-update-to-apply" => ["replication-group-id"],
        "another-update-to-apply" => ["another-replication-group-id"],
      )
    end
  end

  context "with a single update available for multiple instances" do
    when_elasticache_returns [
      {
        service_update_name: "an-update-to-apply",
        replication_group_id: "replication-group-id",
        update_action_status: "not-applied",
      },
      {
        service_update_name: "an-update-to-apply",
        replication_group_id: "another-replication-group-id",
        update_action_status: "not-applied",
      },
    ]

    it "finds a both instance to update" do
      finder = ElastiCacheUpdateFinder.new(elasticache_client)
      expect(finder.find_replication_groups_to_update).to eq(
        "an-update-to-apply" => [
          "replication-group-id",
          "another-replication-group-id",
        ],
      )
    end
  end

  context "with only complete updates" do
    when_elasticache_returns [
      {
        service_update_name: "a-complete-update",
        replication_group_id: "replication-group-id",
        update_action_status: "complete",
      },
    ]

    it "finds a single instance to update" do
      finder = ElastiCacheUpdateFinder.new(elasticache_client)
      expect(finder.find_replication_groups_to_update).to have_attributes(length: 0)
    end
  end
end
