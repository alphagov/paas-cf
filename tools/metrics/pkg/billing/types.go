package billing

import (
	"code.cloudfoundry.org/lager"
)

type CostByPlan struct {
	PlanGUID string  `json:"plan_guid"`
	Cost     float64 `json:"cost"`
}

type Plan struct {
	PlanGUID string `json:"plan_guid"`
	Name     string `json:"name"`

	// Additional fields omitted see alphagov/paas-billing
}

type Client struct {
	logger             lager.Logger
	billingAPIEndpoint string
}
