package main

import (
	"fmt"
	"time"

	"code.cloudfoundry.org/lager"
	uaaclient "github.com/cloudfoundry-community/go-uaa"

	m "github.com/alphagov/paas-cf/tools/metrics/pkg/metrics"
)

type UAAClientConfig struct {
	Endpoint     string
	ClientID     string
	ClientSecret string
}

func UAAGauges(
	logger lager.Logger,
	cfg *UAAClientConfig,
	interval time.Duration,
) m.MetricReadCloser {
	return m.NewMetricPoller(interval, func(w m.MetricWriter) error {
		lsession := logger.Session("uaa-gauges")

		metrics, err := UAAMetrics(lsession, cfg)
		if err != nil {
			lsession.Error("Failed to get UAA metrics", err)
			return err
		}

		lsession.Info("Writing UAA metrics")
		return w.WriteMetrics(metrics)
	})
}

func UAAMetrics(logger lager.Logger, cfg *UAAClientConfig) ([]m.Metric, error) {
	lsession := logger.Session("uaa-metrics")
	lsession.Info("Started UAA metrics")

	uaa := uaaclient.New(cfg.Endpoint, "").WithClientCredentials(
		cfg.ClientID, cfg.ClientSecret, uaaclient.JSONWebToken,
	)

	err := uaa.Validate()
	if err != nil {
		lsession.Error("Failed to validate UAA client", err)
		return []m.Metric{}, err
	}
	lsession.Info("Validated UAA client")

	users, err := uaa.ListAllUsers("", "", "origin,lastLogonTime", "")
	if err != nil {
		lsession.Error("Failed to list all UAA users", err)
		return []m.Metric{}, err
	}
	lsession.Info("Listed all UAA users")

	metrics := make([]m.Metric, 0)

	lsession.Info("Computing UAA users by origin")
	metrics = append(metrics, UAAUsersByOriginGauges(users)...)

	lsession.Info("Computing active UAA users by origin")
	metrics = append(metrics, UAAActiveUsersByOriginGauges(users)...)

	lsession.Info(fmt.Sprintf("Found %d metrics", len(metrics)))

	lsession.Info("Finished UAA metrics")
	return metrics, nil
}

func UAAUsersByOriginGauges(users []uaaclient.User) []m.Metric {
	usersByOriginCount := make(map[string]int, 0)
	for _, user := range users {
		usersByOriginCount[user.Origin] += 1
	}

	metrics := make([]m.Metric, 0)
	for origin, usersCount := range usersByOriginCount {
		metrics = append(metrics, m.Metric{
			Kind:  m.Gauge,
			Time:  time.Now(),
			Name:  "uaa.users",
			Value: float64(usersCount),
			Tags: m.MetricTags{
				{Label: "origin", Value: origin},
			},
			Unit: "count",
		})
	}

	return metrics
}

func UAAActiveUsers(users []uaaclient.User) []uaaclient.User {
	activeUsers := make([]uaaclient.User, 0)

	thirtyDaysAgo := time.Now().Truncate(24 * time.Hour).Add(-1 * 30 * 24 * time.Hour)
	thirtyDaysAgoTimestamp := thirtyDaysAgo.Unix()

	for _, user := range users {
		lastLogonTimestamp := int64(user.LastLogonTime / 1000)

		if lastLogonTimestamp >= thirtyDaysAgoTimestamp {
			activeUsers = append(activeUsers, user)
		}
	}

	return activeUsers
}

func UAAActiveUsersByOriginGauges(users []uaaclient.User) []m.Metric {
	usersByOriginCount := make(map[string]int, 0)

	for _, user := range UAAActiveUsers(users) {
		usersByOriginCount[user.Origin] += 1
	}

	metrics := make([]m.Metric, 0)
	for origin, usersCount := range usersByOriginCount {
		metrics = append(metrics, m.Metric{
			Kind:  m.Gauge,
			Time:  time.Now(),
			Name:  "uaa.active.users",
			Value: float64(usersCount),
			Tags: m.MetricTags{
				{Label: "origin", Value: origin},
			},
			Unit: "count",
		})
	}

	return metrics
}
