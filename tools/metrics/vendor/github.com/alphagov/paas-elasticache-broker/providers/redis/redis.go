package redis

import (
	"context"
	"encoding/base32"
	"fmt"
	"hash/fnv"
	"net/url"
	"strings"

	"code.cloudfoundry.org/lager"
	"github.com/alphagov/paas-elasticache-broker/providers"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/awserr"
	"github.com/aws/aws-sdk-go/service/elasticache"
	"github.com/aws/aws-sdk-go/service/secretsmanager"
)

var _ providers.Provider = &RedisProvider{}

const PasswordLength = 32

// RedisProvider is the Redis broker provider
type RedisProvider struct {
	elastiCache        providers.ElastiCache
	secretsManager     providers.SecretsManager
	awsAccountID       string
	awsPartition       string
	awsRegion          string
	logger             lager.Logger
	kmsKeyID           string
	secretsManagerPath string
}

// NewProvider creates a new Redis provider
func NewProvider(
	elastiCache providers.ElastiCache,
	secretsManager providers.SecretsManager,
	awsAccountID, awsPartition,
	awsRegion string,
	logger lager.Logger,
	kmsKeyID string,
	secretsManagerPath string,
) *RedisProvider {
	return &RedisProvider{
		elastiCache:        elastiCache,
		secretsManager:     secretsManager,
		awsAccountID:       awsAccountID,
		awsPartition:       awsPartition,
		awsRegion:          awsRegion,
		logger:             logger,
		kmsKeyID:           kmsKeyID,
		secretsManagerPath: strings.TrimRight(secretsManagerPath, "/"),
	}
}

func (p *RedisProvider) createCacheParameterGroup(ctx context.Context, replicationGroupID string, params providers.ProvisionParameters) error {
	_, err := p.elastiCache.CreateCacheParameterGroupWithContext(ctx, &elasticache.CreateCacheParameterGroupInput{
		CacheParameterGroupFamily: aws.String("redis3.2"),
		CacheParameterGroupName:   aws.String(replicationGroupID),
		Description:               aws.String("Created by Cloud Foundry"),
	})
	if err != nil {
		return err
	}

	if params.Parameters == nil {
		params.Parameters = map[string]string{}
	}
	if _, set := params.Parameters["cluster-enabled"]; !set {
		params.Parameters["cluster-enabled"] = "no"
	}

	return p.modifyCacheParameterGroup(ctx, replicationGroupID, params.Parameters)
}

func (p *RedisProvider) modifyCacheParameterGroup(ctx context.Context, replicationGroupID string, params map[string]string) error {
	if len(params) == 0 {
		return nil
	}

	pgParams := []*elasticache.ParameterNameValue{}
	for paramName, paramValue := range params {
		pgParams = append(pgParams, &elasticache.ParameterNameValue{
			ParameterName:  aws.String(paramName),
			ParameterValue: aws.String(paramValue),
		})
	}

	_, err := p.elastiCache.ModifyCacheParameterGroupWithContext(ctx, &elasticache.ModifyCacheParameterGroupInput{
		ParameterNameValues:     pgParams,
		CacheParameterGroupName: aws.String(replicationGroupID),
	})
	return err
}

func (p *RedisProvider) DeleteCacheParameterGroup(ctx context.Context, instanceID string) error {
	replicationGroupID := GenerateReplicationGroupName(instanceID)
	_, err := p.elastiCache.DeleteCacheParameterGroupWithContext(ctx, &elasticache.DeleteCacheParameterGroupInput{
		CacheParameterGroupName: aws.String(replicationGroupID),
	})
	if err != nil {
		if awsErr, ok := err.(awserr.Error); ok {
			if awsErr.Code() == elasticache.ErrCodeCacheParameterGroupNotFoundFault {
				return nil
			}
		}
	}
	return err
}

func (p *RedisProvider) Update(ctx context.Context, instanceID string, params providers.UpdateParameters) error {
	replicationGroupID := GenerateReplicationGroupName(instanceID)
	return p.modifyCacheParameterGroup(ctx, replicationGroupID, params.Parameters)
}

// Provision creates a replication group and a cache parameter group
func (p *RedisProvider) Provision(ctx context.Context, instanceID string, params providers.ProvisionParameters) error {
	replicationGroupID := GenerateReplicationGroupName(instanceID)

	err := p.createCacheParameterGroup(ctx, replicationGroupID, params)
	if err != nil {
		return err
	}

	cacheParameterGroupName := replicationGroupID

	authToken := GenerateAuthToken()
	err = p.CreateAuthTokenSecret(ctx, instanceID, authToken)
	if err != nil {
		return fmt.Errorf("failed to create auth token: %s", err.Error())
	}

	input := &elasticache.CreateReplicationGroupInput{
		Tags: []*elasticache.Tag{},
		AtRestEncryptionEnabled:     aws.Bool(true),
		TransitEncryptionEnabled:    aws.Bool(true),
		AuthToken:                   aws.String(authToken),
		AutomaticFailoverEnabled:    aws.Bool(params.AutomaticFailoverEnabled),
		CacheNodeType:               aws.String(params.InstanceType),
		CacheParameterGroupName:     aws.String(cacheParameterGroupName),
		SecurityGroupIds:            aws.StringSlice(params.SecurityGroupIds),
		CacheSubnetGroupName:        aws.String(params.CacheSubnetGroupName),
		Engine:                      aws.String("redis"),
		EngineVersion:               aws.String("3.2.6"),
		PreferredMaintenanceWindow:  aws.String(params.PreferredMaintenanceWindow),
		ReplicationGroupDescription: aws.String(params.Description),
		ReplicationGroupId:          aws.String(replicationGroupID),
		NumNodeGroups:               aws.Int64(params.ShardCount),
		ReplicasPerNodeGroup:        aws.Int64(params.ReplicasPerNodeGroup),
		SnapshotName:                params.RestoreFromSnapshot,
	}

	if params.SnapshotRetentionLimit > 0 {
		input.SetSnapshotRetentionLimit(params.SnapshotRetentionLimit)
		input.SetSnapshotWindow("02:00-05:00")
	}

	for tagName, tagValue := range params.Tags {
		input.Tags = append(input.Tags, &elasticache.Tag{
			Key:   aws.String(tagName),
			Value: aws.String(tagValue),
		})
	}

	_, createErr := p.elastiCache.CreateReplicationGroupWithContext(ctx, input)
	if createErr != nil {
		err := p.DeleteCacheParameterGroup(ctx, instanceID)
		if err != nil {
			p.logger.Error("delete-cache-parameter-group", err)
		}
		err = p.DeleteAuthTokenSecret(ctx, instanceID, 7)
		if err != nil {
			p.logger.Error("delete-auth-token-secret", err)
		}
	}
	return createErr
}

// Deprovision deletes the replication group
func (p *RedisProvider) Deprovision(ctx context.Context, instanceID string, params providers.DeprovisionParameters) error {
	replicationGroupID := GenerateReplicationGroupName(instanceID)

	input := &elasticache.DeleteReplicationGroupInput{
		ReplicationGroupId: aws.String(replicationGroupID),
	}
	if params.FinalSnapshotIdentifier != "" {
		input.SetFinalSnapshotIdentifier(params.FinalSnapshotIdentifier)
	}

	_, err := p.elastiCache.DeleteReplicationGroupWithContext(ctx, input)
	if err != nil {
		return err
	}

	err = p.DeleteAuthTokenSecret(ctx, instanceID, 30)
	if err != nil {
		return err
	}

	return nil
}

func (p *RedisProvider) getMessage(ctx context.Context, replicationGroup *elasticache.ReplicationGroup) string {
	tmpl := "%-20s : %s"
	msgs := []string{"---"}
	if replicationGroup.Status != nil {
		msgs = append(msgs, fmt.Sprintf(tmpl, "status", *replicationGroup.Status))
	} else {
		msgs = append(msgs, fmt.Sprintf(tmpl, "status", "unknown"))
	}
	if replicationGroup.ReplicationGroupId != nil {
		msgs = append(msgs, fmt.Sprintf(tmpl, "cluster id", *replicationGroup.ReplicationGroupId))
	}

	if len(replicationGroup.MemberClusters) > 0 && replicationGroup.MemberClusters[0] != nil {
		cacheClusterId := replicationGroup.MemberClusters[0]
		if cacheCluster, err := p.describeCacheCluster(ctx, *cacheClusterId); err == nil {

			if cacheCluster.EngineVersion != nil {
				msgs = append(msgs, fmt.Sprintf(tmpl, "engine version", *cacheCluster.EngineVersion))
			}

			if replicationGroup.ReplicationGroupId != nil {
				if params, err := p.describeCacheParameters(ctx, *replicationGroup.ReplicationGroupId); err == nil {
					for _, param := range params {
						if param.ParameterName == nil {
							continue
						}
						if *param.ParameterName == "maxmemory-policy" && param.ParameterValue != nil {
							msgs = append(msgs, fmt.Sprintf(tmpl, "maxmemory policy", strings.TrimSpace(*param.ParameterValue)))
						}
						if *param.ParameterName == "cluster-enabled" && param.ParameterValue != nil {
							msgs = append(msgs, fmt.Sprintf(tmpl, "cluster enabled", strings.TrimSpace(*param.ParameterValue)))
						}
					}
				}
			}

			if cacheCluster.PreferredMaintenanceWindow != nil {
				msgs = append(msgs, fmt.Sprintf(tmpl, "maintenance window", *cacheCluster.PreferredMaintenanceWindow))
			}
		}
	}

	if replicationGroup.SnapshotWindow != nil {
		msgs = append(msgs, fmt.Sprintf(tmpl, "daily backup window", *replicationGroup.SnapshotWindow))
	}

	return strings.Join(msgs, "\n           ")
}

// GetState returns with the state of an existing cluster
// If the cluster doesn't exist we return with the providers.NonExisting state
func (p *RedisProvider) GetState(ctx context.Context, instanceID string) (providers.ServiceState, string, error) {
	replicationGroupID := GenerateReplicationGroupName(instanceID)

	replicationGroup, err := p.describeReplicationGroup(ctx, replicationGroupID)
	if err != nil {
		if awsErr, ok := err.(awserr.Error); ok {
			if awsErr.Code() == elasticache.ErrCodeReplicationGroupNotFoundFault {
				return providers.NonExisting, fmt.Sprintf("Replication group does not exist: %s", replicationGroupID), nil
			}
		}
		return providers.ServiceState(""), "", err
	}

	if replicationGroup.Status == nil {
		return providers.ServiceState(""), "", fmt.Errorf("Invalid response from AWS: status is missing for %s", replicationGroupID)
	}

	message := p.getMessage(ctx, replicationGroup)

	return providers.ServiceState(*replicationGroup.Status), message, nil
}

func (p *RedisProvider) describeReplicationGroup(ctx context.Context, replicationGroupID string) (*elasticache.ReplicationGroup, error) {
	output, err := p.elastiCache.DescribeReplicationGroupsWithContext(ctx, &elasticache.DescribeReplicationGroupsInput{
		ReplicationGroupId: aws.String(replicationGroupID),
	})

	if err != nil {
		return nil, err
	}

	if output.ReplicationGroups == nil || len(output.ReplicationGroups) == 0 {
		return nil, fmt.Errorf("Invalid response from AWS: no replication groups returned for %s", replicationGroupID)
	}

	return output.ReplicationGroups[0], nil
}

func (p *RedisProvider) describeCacheCluster(ctx context.Context, cacheClusterID string) (*elasticache.CacheCluster, error) {
	output, err := p.elastiCache.DescribeCacheClustersWithContext(ctx, &elasticache.DescribeCacheClustersInput{
		CacheClusterId: aws.String(cacheClusterID),
	})

	if err != nil {
		return nil, err
	}

	if len(output.CacheClusters) == 0 {
		return nil, fmt.Errorf("Invalid response from AWS: no CacheClusters found for %s", cacheClusterID)
	}

	return output.CacheClusters[0], nil
}

func (p *RedisProvider) describeCacheParameters(ctx context.Context, cacheParameterGroupName string) ([]*elasticache.Parameter, error) {
	output, err := p.elastiCache.DescribeCacheParametersWithContext(ctx, &elasticache.DescribeCacheParametersInput{
		CacheParameterGroupName: aws.String(cacheParameterGroupName),
	})

	if err != nil {
		return nil, err
	}

	return output.Parameters, nil
}

// GenerateCredentials generates the client credentials for a Redis instance and an app
func (p *RedisProvider) GenerateCredentials(ctx context.Context, instanceID, bindingID string) (*providers.Credentials, error) {
	replicationGroupID := GenerateReplicationGroupName(instanceID)

	replicationGroup, err := p.describeReplicationGroup(ctx, replicationGroupID)
	if err != nil {
		if awsErr, ok := err.(awserr.Error); ok {
			if awsErr.Code() == elasticache.ErrCodeReplicationGroupNotFoundFault {
				return nil, fmt.Errorf("Replication group does not exist: %s", replicationGroupID)
			}
		}
		return nil, err
	}

	var host string
	var port int64

	if replicationGroup.ConfigurationEndpoint != nil {
		host = *replicationGroup.ConfigurationEndpoint.Address
		port = *replicationGroup.ConfigurationEndpoint.Port
	} else {
		if replicationGroup.NodeGroups == nil || len(replicationGroup.NodeGroups) == 0 {
			return nil, fmt.Errorf("Invalid response from AWS: no node groups returned for %s", replicationGroupID)
		}
		host = *replicationGroup.NodeGroups[0].PrimaryEndpoint.Address
		port = *replicationGroup.NodeGroups[0].PrimaryEndpoint.Port
	}

	authTokenSecret, err := p.secretsManager.GetSecretValueWithContext(ctx, &secretsmanager.GetSecretValueInput{
		SecretId: aws.String(p.getAuthTokenPath(instanceID)),
	})
	if err != nil {
		return nil, err
	}
	authToken := aws.StringValue(authTokenSecret.SecretString)

	uri := &url.URL{
		Scheme: "rediss",
		Host:   fmt.Sprintf("%s:%d", host, port),
		User:   url.UserPassword("x", authToken),
	}
	return &providers.Credentials{
		Host:       host,
		Port:       port,
		Name:       replicationGroupID,
		Password:   authToken,
		TLSEnabled: true,
		URI:        uri.String(),
	}, nil
}

// RevokeCredentials revokes the credentials between an app and a Redis instance
//
// The method does nothing because we can't revoke the credentials as there is one common password
// for a Redis service instance
func (p *RedisProvider) RevokeCredentials(ctx context.Context, instanceID, bindingID string) error {
	return nil
}

// FindSnapshots returns the list of snapshots found for a given instance ID
func (p *RedisProvider) FindSnapshots(ctx context.Context, instanceID string) ([]providers.SnapshotInfo, error) {
	replicationGroupID := GenerateReplicationGroupName(instanceID)
	describeSnapshotsParams := &elasticache.DescribeSnapshotsInput{
		ReplicationGroupId: aws.String(replicationGroupID),
	}
	snapshots := []*elasticache.Snapshot{}
	err := p.elastiCache.DescribeSnapshotsPagesWithContext(ctx, describeSnapshotsParams, func(page *elasticache.DescribeSnapshotsOutput, lastPage bool) bool {
		snapshots = append(snapshots, page.Snapshots...)
		return true
	})
	if err != nil {
		return nil, err
	}

	snapshotInfos := []providers.SnapshotInfo{}
	for _, snapshot := range snapshots {
		if snapshot.SnapshotName == nil ||
			len(snapshot.NodeSnapshots) == 0 ||
			snapshot.NodeSnapshots[0].SnapshotCreateTime == nil {
			return nil, fmt.Errorf("Invalid response from AWS: Missing values for snapshot for elasticache cluster %s", instanceID)
		}
		tagList, err := p.elastiCache.ListTagsForResourceWithContext(ctx, &elasticache.ListTagsForResourceInput{
			ResourceName: aws.String(p.snapshotARN(*snapshot.SnapshotName)),
		})
		if err != nil {
			return nil, err
		}
		snapshotInfos = append(snapshotInfos, providers.SnapshotInfo{
			Name:       *snapshot.SnapshotName,
			CreateTime: *snapshot.NodeSnapshots[0].SnapshotCreateTime,
			Tags:       tagsValues(tagList.TagList),
		})
	}
	return snapshotInfos, nil
}

func (p *RedisProvider) snapshotARN(snapshotID string) string {
	return fmt.Sprintf("arn:%s:elasticache:%s:%s:snapshot:%s", p.awsPartition, p.awsRegion, p.awsAccountID, snapshotID)
}

func (p *RedisProvider) CreateAuthTokenSecret(ctx context.Context, instanceID string, authToken string) error {
	name := p.getAuthTokenPath(instanceID)
	_, err := p.secretsManager.CreateSecretWithContext(ctx, &secretsmanager.CreateSecretInput{
		Name:         aws.String(name),
		SecretString: aws.String(authToken),
		KmsKeyId:     aws.String(p.kmsKeyID),
	})
	return err
}

func (p *RedisProvider) DeleteAuthTokenSecret(ctx context.Context, instanceID string, recoveryWindowInDays int) error {
	name := p.getAuthTokenPath(instanceID)
	_, err := p.secretsManager.DeleteSecretWithContext(ctx, &secretsmanager.DeleteSecretInput{
		SecretId:             aws.String(name),
		RecoveryWindowInDays: aws.Int64(int64(recoveryWindowInDays)),
	})
	return err
}

func (p *RedisProvider) getAuthTokenPath(instanceID string) string {
	return fmt.Sprintf("%s/%s/auth-token", p.secretsManagerPath, instanceID)
}

func tagsValues(elasticacheTags []*elasticache.Tag) map[string]string {
	tags := map[string]string{}
	if elasticacheTags == nil {
		return tags
	}
	for _, t := range elasticacheTags {
		tags[aws.StringValue(t.Key)] = aws.StringValue(t.Value)
	}
	return tags
}

// GenerateReplicationGroupName generates a valid ElastiCache replication group name
// A valid name must contain between 1 and 20 alphanumeric characters or hyphens, should start with a letter, and cannot end with a hyphen or contain two consecutive hyphens.
func GenerateReplicationGroupName(instanceID string) string {
	hash := fnv.New64a()
	hash.Write([]byte(instanceID))
	out := hash.Sum([]byte{})
	encoder := base32.StdEncoding.WithPadding(base32.NoPadding)
	return strings.ToLower("cf-" + encoder.EncodeToString(out))
}

// GenerateAuthToken generates an alphanumeric cryptographically-secure password
func GenerateAuthToken() string {
	return RandomAlphaNum(PasswordLength)
}
