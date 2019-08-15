package billing

import (
	"time"

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

type CurrencyRate struct {
	Code      string    `json:"code"`
	Rate      float64   `json:"rate"`
	ValidFrom time.Time `json:"valid_from"`
}

type Client struct {
	logger             lager.Logger
	billingAPIEndpoint string
}
