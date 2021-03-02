package servicequotas

import (
	"github.com/aws/aws-sdk-go/service/servicequotas/servicequotasiface"
)

type ServiceQuotas struct {
	Client servicequotasiface.ServiceQuotasAPI
}
