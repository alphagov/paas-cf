package providers

import (
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/request"
	"github.com/aws/aws-sdk-go/service/secretsmanager"
)

// SecretsManager is a partially extracted interface from the AWS Elasticache SDK
//
//go:generate counterfeiter -o mocks/secretsmanager.go . SecretsManager
type SecretsManager interface {
	CreateSecretWithContext(ctx aws.Context, input *secretsmanager.CreateSecretInput, opts ...request.Option) (*secretsmanager.CreateSecretOutput, error)
	GetSecretValueWithContext(ctx aws.Context, input *secretsmanager.GetSecretValueInput, opts ...request.Option) (*secretsmanager.GetSecretValueOutput, error)
	DeleteSecretWithContext(ctx aws.Context, input *secretsmanager.DeleteSecretInput, opts ...request.Option) (*secretsmanager.DeleteSecretOutput, error)
}
