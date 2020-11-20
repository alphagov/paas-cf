package shield

import (
	"github.com/aws/aws-sdk-go/service/shield/shieldiface"
)

type ShieldService struct {
	Client shieldiface.ShieldAPI
}

type ShieldServiceInterface interface {
	CountOnGoingAttacks() (int, error)
}

