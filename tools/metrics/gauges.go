package main

import (
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
		started := 0
		stopped := 0
		for _, app := range apps {
			if app.State == "STARTED" {
				started += 1
			}
			if app.State == "STOPPED" {
				stopped += 1
			}
		}
		return w.WriteMetrics([]Metric{
			{
				Kind:  Gauge,
				Time:  time.Now(),
				Name:  "apps.count",
				Value: float64(started),
				Tags:  []string{"state:running"},
			},
			{
				Kind:  Gauge,
				Time:  time.Now(),
				Name:  "apps.count",
				Value: float64(stopped),
				Tags:  []string{"state:stopped"},
			},
		})
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
		counters := map[string]int{}
		for _, instance := range serviceInstances {
			service := findService(services, instance.ServiceGuid)
			if service == nil {
				continue
			}
			if service.Label == "" {
				continue
			}
			counters[service.Label]++
		}
		metrics := []Metric{}
		for serviceName, count := range counters {
			metrics = append(metrics, Metric{
				Kind:  Gauge,
				Time:  time.Now(),
				Name:  "services.provisioned",
				Value: float64(count),
				Tags:  []string{"type:" + serviceName},
			})

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
				return err
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
