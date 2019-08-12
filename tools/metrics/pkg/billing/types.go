package billing

import (
	"code.cloudfoundry.org/lager"
)

type CostByPlan struct {
	PlanGUID string  `json:"plan_guid"`
	Cost     float64 `json:"cost"`
}

type Client struct {
	logger             lager.Logger
	billingAPIEndpoint string
}
