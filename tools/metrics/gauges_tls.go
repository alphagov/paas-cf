package main

import (
	"crypto/tls"
	"net"
	"strings"
	"time"

	"code.cloudfoundry.org/lager"

	"github.com/alphagov/paas-cf/tools/metrics/pkg/cloudfront"
	"github.com/alphagov/paas-cf/tools/metrics/pkg/tlscheck"
)

func TLSValidityGauge(
	logger lager.Logger,
	certChecker tlscheck.CertChecker,
	addr string,
	interval time.Duration,
) MetricReadCloser {
	return NewMetricPoller(interval, func(w MetricWriter) error {
		if !strings.Contains(addr, ":") {
			addr += ":443"
		}
		host, _, err := net.SplitHostPort(addr)
		if err != nil {
			return err
		}

		daysUntilExpiry, err := certChecker.DaysUntilExpiry(addr, &tls.Config{})
		if err != nil {
			logger.Error("tls-certificates-validity-failure", err, lager.Data{
				"addr":     addr,
				"hostname": host,
			})
			return err
		}

		metric := Metric{
			Kind:  Gauge,
			Time:  time.Now(),
			Name:  "tls.certificates.validity",
			Value: daysUntilExpiry,
			Tags: MetricTags{
				{Label: "hostname", Value: host},
			},
			Unit: "days",
		}
		return w.WriteMetrics([]Metric{metric})
	})
}

func CDNTLSValidityGauge(
	logger lager.Logger,
	certChecker tlscheck.CertChecker,
	cfs *cloudfront.CloudFrontService,
	interval time.Duration,
) MetricReadCloser {
	return NewMetricPoller(interval, func(w MetricWriter) error {
		customDomains, err := cfs.CustomDomains()
		if err != nil {
			logger.Error("cloudfront-list-distributions-failure", err, lager.Data{})
			return err
		}

		metrics := []Metric{}
		for _, customDomain := range customDomains {
			daysUntilExpiry, err := certChecker.DaysUntilExpiry(
				customDomain.CloudFrontDomain+":443",
				&tls.Config{ServerName: customDomain.AliasDomain},
			)
			if err != nil {
				logger.Error("cdn-tls-certificates-validity-failure", err, lager.Data{
					"alias_domain":      customDomain.AliasDomain,
					"cloudfront_domain": customDomain.CloudFrontDomain,
				})
			}

			var validity int
			if err == nil {
				validity = 1
				metrics = append(metrics, Metric{
					Kind:  Gauge,
					Time:  time.Now(),
					Name:  "cdn.tls.certificates.expiry",
					Value: daysUntilExpiry,
					Tags: MetricTags{
						{Label: "hostname", Value: customDomain.AliasDomain},
					},
					Unit: "days",
				})
			}

			metrics = append(metrics, Metric{
				Kind:  Gauge,
				Time:  time.Now(),
				Name:  "cdn.tls.certificates.validity",
				Value: float64(validity),
				Tags: MetricTags{
					{Label: "hostname", Value: customDomain.AliasDomain},
				},
				Unit: "",
			})
		}
		return w.WriteMetrics(metrics)
	})
}
