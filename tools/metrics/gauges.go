package main

import (
	"fmt"
	"log"
	"net/url"
	"time"

	cfclient "github.com/cloudfoundry-community/go-cfclient"
)

func QuotaGauge(c *Client, interval time.Duration) MetricReadCloser {
	return NewMetricPoller(interval, func(w MetricWriter) error {
		orgs, err := c.cf.ListOrgs()
		if err != nil {
			return err
		}

		reservedMemory := 0
		reservedServices := 0
		allocatedMemory := 0
		allocatedServices := 0
		reservedRoutes := 0

		for _, org := range orgs {
			quota, err := org.Quota()
			if err != nil {
				return err
			}
			reservedMemory += quota.MemoryLimit
			reservedServices += quota.TotalServices
			reservedRoutes += quota.TotalRoutes
		}

		apps, err := c.cf.ListApps()
		if err != nil {
			return err
		}
		for _, app := range apps {
			allocatedMemory += (app.Memory * app.Instances)
		}

		allocatedServices, err = c.CountServiceInstances()
		if err != nil {
			return err
		}

		return w.WriteMetrics([]Metric{
			{
				Kind:  Gauge,
				Time:  time.Now(),
				Name:  "quota.services.reserved", // number of services reserved by quotas
				Value: float64(reservedServices),
			},
			{
				Kind:  Gauge,
				Time:  time.Now(),
				Name:  "quota.services.allocated", // number of services in use
				Value: float64(allocatedServices),
			},
			{
				Kind:  Gauge,
				Time:  time.Now(),
				Name:  "quota.memory.reserved", // memory reserved by org quotas
				Value: float64(reservedMemory),
			},
			{
				Kind:  Gauge,
				Time:  time.Now(),
				Name:  "quota.memory.allocated", // memory allocated to apps
				Value: float64(allocatedMemory),
			},
			{
				Kind:  Gauge,
				Time:  time.Now(),
				Name:  "quota.routes.reserved", // number of routes reserved
				Value: float64(reservedRoutes),
			},
		})
	})
}

func UserCountGauge(c *Client, interval time.Duration) MetricReadCloser {
	return NewMetricPoller(interval, func(w MetricWriter) error {
		// global auditor role cannot use /v2/users
		// so we have to fetch users from each org
		orgs, err := c.cf.ListOrgs()
		if err != nil {
			return err
		}

		userGuids := map[string]bool{}

		for _, org := range orgs {
			users, err := c.OrgUsers(org.Guid)
			if err != nil {
				return err
			}
			for _, u := range users {
				userGuids[u.Guid] = true
			}
		}

		return w.WriteMetrics([]Metric{
			{
				Kind:  Gauge,
				Time:  time.Now(),
				Name:  "users.count",
				Value: float64(len(userGuids)),
			},
		})
	})
}

func AppCountGauge(c *Client, interval time.Duration) MetricReadCloser {
	return NewMetricPoller(interval, func(w MetricWriter) error {
		apps, err := c.cf.ListApps()
		if err != nil {
			return err
		}

		// Number of relevant apps in
		// - APP_STATE: string of whether each app is "started" or "stopped"
		// - ORG_IS_TRIAL: boolean of whether each app is owned by a trial organisation
		// counters[APP_STATE][ORG_IS_TRIAL]
		counters := map[string]map[bool]int{
			"started": map[bool]int{},
			"stopped": map[bool]int{},
		}
		for _, app := range apps {
			org_quota, err := findOrgQuotaFromSpaceGUID(c, app.SpaceGuid)
			if err != nil {
				log.Printf("Error finding org quota for space %s for app %s: %s\n", app.SpaceGuid, app.Guid, err)
				continue
			}
			org_is_trial := isOrgQuotaTrial(org_quota)
			if app.State == "STARTED" {
				counters["started"][org_is_trial]++
			}
			if app.State == "STOPPED" {
				counters["stopped"][org_is_trial]++
			}
		}

		metrics := []Metric{}
		for state, count_by_trial := range counters {
			for org_is_trial, count := range count_by_trial {
				metrics = append(metrics, Metric{
					Kind:  Gauge,
					Time:  time.Now(),
					Name:  "apps.count",
					Value: float64(count),
					Tags: []string{
						"state:" + state,
						fmt.Sprintf("trial_org:%t", org_is_trial),
					},
				})
			}
		}
		return w.WriteMetrics(metrics)
	})
}

func ServiceCountGauge(c *Client, interval time.Duration) MetricReadCloser {
	return NewMetricPoller(interval, func(w MetricWriter) error {
		serviceInstances, err := c.cf.ListServiceInstances()
		if err != nil {
			return err
		}
		services, err := c.cf.ListServices()
		if err != nil {
			return nil
		}
		service_plans, err := c.cf.ListServicePlans()
		if err != nil {
			return nil
		}

		// Number of relevant service instances in
		// - ORG_IS_TRIAL: boolean of whether each app is owned by a trial organisation
		// - SERVICE_PLAN_IS_FREE: whether the instance's service plan is free
		// - NAME_OF_SERVICE: e.g., "mysql" or "postgres"
		// counters[ORG_IS_TRIAL][SERVICE_PLAN_IS_FREE][NAME_OF_SERVICE]
		counters := map[bool]map[bool]map[string]int{
			true: map[bool]map[string]int{
				true:  map[string]int{},
				false: map[string]int{},
			},
			false: map[bool]map[string]int{
				true:  map[string]int{},
				false: map[string]int{},
			},
		}
		for _, instance := range serviceInstances {
			service := findService(services, instance.ServiceGuid)
			if service == nil {
				log.Printf("Service was not found for service instance %s\n", instance.Guid)
				continue
			}
			if service.Label == "" {
				log.Printf("Service label was empty for service %s and service instance %s\n", service.Guid, instance.Guid)
				continue
			}
			service_plan := findServicePlan(service_plans, instance.ServicePlanGuid)
			if service_plan == nil {
				log.Printf("Error finding service plan for service instance %s: %s\n", instance.Guid, err)
				continue
			}
			org_quota, err := findOrgQuotaFromSpaceGUID(c, instance.SpaceGuid)
			if err != nil {
				log.Printf("Error finding org quota for space %s for service instance %s: %s\n", instance.SpaceGuid, instance.Guid, err)
				continue
			}
			org_is_trial := isOrgQuotaTrial(org_quota)
			service_plan_is_free := isServicePlanFree(service_plan)
			counters[org_is_trial][service_plan_is_free][service.Label]++
		}

		metrics := []Metric{}
		for org_is_trial, x := range counters {
			for service_plan_is_free, y := range x {
				for service_label, count := range y {
					metrics = append(metrics, Metric{
						Kind:  Gauge,
						Time:  time.Now(),
						Name:  "services.provisioned",
						Value: float64(count),
						Tags: []string{
							"type:" + service_label,
							fmt.Sprintf("trial_org:%t", org_is_trial),
							fmt.Sprintf("free_service:%t", service_plan_is_free),
						},
					})
				}
			}
		}
		return w.WriteMetrics(metrics)
	})
}

func OrgCountGauge(c *Client, interval time.Duration) MetricReadCloser {
	return NewMetricPoller(interval, func(w MetricWriter) error {
		orgs, err := c.cf.ListOrgs()
		if err != nil {
			return err
		}
		counters := map[string]int{}
		for _, org := range orgs {
			quota, err := org.Quota()
			if err != nil {
				log.Printf("Error finding org quota for org %s: %s\n", org.Guid, err)
				continue
			}
			counters[quota.Name]++
		}
		metrics := []Metric{}
		for name, count := range counters {
			metrics = append(metrics, Metric{
				Kind:  Gauge,
				Time:  time.Now(),
				Name:  "orgs.count",
				Value: float64(count),
				Tags:  []string{"quota:" + name},
			})
		}
		return w.WriteMetrics(metrics)
	})
}

func SpaceCountGauge(c *Client, interval time.Duration) MetricReadCloser {
	return NewMetricPoller(interval, func(w MetricWriter) error {
		spaces, err := c.cf.ListSpaces()
		if err != nil {
			return err
		}
		return w.WriteMetrics([]Metric{
			{
				Kind:  Gauge,
				Time:  time.Now(),
				Name:  "spaces.count",
				Value: float64(len(spaces)),
			},
		})
	})
}

func EventCountGauge(c *Client, eventType string, interval time.Duration) MetricReadCloser {
	return NewMetricPoller(interval, func(w MetricWriter) error {
		u, err := url.Parse("/v2/events")
		if err != nil {
			return err
		}
		maxAge := time.Now().Add(-1 * interval)
		q := u.Query()
		q.Set("order-direction", "desc")
		q.Set("results-per-page", "100")
		q.Add("q", "type:"+eventType)
		q.Add("q", "timestamp>"+maxAge.Format(time.RFC3339Nano))
		u.RawQuery = q.Encode()
		batchUrl := u.String()
		gauge := Metric{
			Time: time.Now(),
			Kind: Gauge,
			Name: "events." + eventType,
		}
		for batchUrl != "" {
			var batch struct {
				NextUrl   string          `json:"next_url"`
				Resources []AppUsageEvent `json:"resources"`
			}
			if err := c.get(batchUrl, &batch); err != nil {
				return err
			}
			for _, res := range batch.Resources {
				if res.MetaData.CreatedAt.Before(maxAge) {
					break
				}
				gauge.Value += 1
			}
			batchUrl = batch.NextUrl
		}
		return w.WriteMetrics([]Metric{gauge})
	})
}

func findService(services []cfclient.Service, guid string) *cfclient.Service {
	for _, service := range services {
		if service.Guid == guid {
			return &service
		}
	}
	return nil
}

func findServicePlan(service_plans []cfclient.ServicePlan, guid string) *cfclient.ServicePlan {
	for _, service_plan := range service_plans {
		if service_plan.Guid == guid {
			return &service_plan
		}
	}
	return nil
}

func findOrgQuotaFromSpaceGUID(c *Client, guid string) (*cfclient.OrgQuota, error) {
	space, err := c.cf.GetSpaceByGuid(guid)
	if err != nil {
		return nil, err
	}
	org, err := space.Org()
	if err != nil {
		return nil, err
	}
	org_quota, err := org.Quota()
	if err != nil {
		return nil, err
	}
	return org_quota, nil
}

// Determine if an organisation is on a trial plan.
func isOrgQuotaTrial(quota *cfclient.OrgQuota) bool {
	return quota.Name == "default"
}

// Determine if a service plan is free.
func isServicePlanFree(plan *cfclient.ServicePlan) bool {
	return plan.Name == "Free"
}
