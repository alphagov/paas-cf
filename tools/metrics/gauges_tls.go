package main

import (
	"crypto/tls"
	"net"
	"strings"
	"time"

	"code.cloudfoundry.org/lager"

	"github.com/alphagov/paas-cf/tools/metrics/pkg/cloudfront"
	m "github.com/alphagov/paas-cf/tools/metrics/pkg/metrics"
	"github.com/alphagov/paas-cf/tools/metrics/pkg/tlscheck"
)

func TLSValidityGauge(
	logger lager.Logger,
	certChecker tlscheck.CertChecker,
	addr string,
	interval time.Duration,
) m.MetricReadCloser {
	return m.NewMetricPoller(interval, func(w m.MetricWriter) error {
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

		metric := m.Metric{
			Kind:  m.Gauge,
			Time:  time.Now(),
			Name:  "tls.certificates.validity",
			Value: daysUntilExpiry,
			Tags: m.MetricTags{
				{Label: "hostname", Value: host},
			},
			Unit: "days",
		}
		return w.WriteMetrics([]m.Metric{metric})
	})
}

func CDNTLSValidityGauge(
	logger lager.Logger,
	certChecker tlscheck.CertChecker,
	cfs *cloudfront.CloudFrontService,
	interval time.Duration,
) m.MetricReadCloser {
	return m.NewMetricPoller(interval, func(w m.MetricWriter) error {
		customDomains, err := cfs.CustomDomains()
		if err != nil {
			logger.Error("cloudfront-list-distributions-failure", err, lager.Data{})
			return err
		}

		metrics := []m.Metric{}
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
				metrics = append(metrics, m.Metric{
					Kind:  m.Gauge,
					Time:  time.Now(),
					Name:  "cdn.tls.certificates.expiry",
					Value: daysUntilExpiry,
					Tags: m.MetricTags{
						{Label: "hostname", Value: customDomain.AliasDomain},
					},
					Unit: "days",
				})
			}

			metrics = append(metrics, m.Metric{
				Kind:  m.Gauge,
				Time:  time.Now(),
				Name:  "cdn.tls.certificates.validity",
				Value: float64(validity),
				Tags: m.MetricTags{
					{Label: "hostname", Value: customDomain.AliasDomain},
				},
				Unit: "",
			})
		}
		return w.WriteMetrics(metrics)
	})
}

func CDNTLSCertificateAuthorityGauge(
	logger lager.Logger,
	certChecker tlscheck.CertChecker,
	cfs *cloudfront.CloudFrontService,
	interval time.Duration,
) m.MetricReadCloser {
	return m.NewMetricPoller(interval, func(w m.MetricWriter) error {
		customDomains, err := cfs.CustomDomains()
		if err != nil {
			logger.Error("cloudfront-list-distributions-failure", err, lager.Data{})
			return err
		}

		certAuthorityCounter := map[string]int{}
		for _, customDomain := range customDomains {
			logger.Info("get-certificate-authority", lager.Data{
				"cloudfront-domain": customDomain.CloudFrontDomain,
				"alias-domain": customDomain.AliasDomain,
			})
			authority, err := certChecker.CertificateAuthority(
				customDomain.CloudFrontDomain+":443",
				&tls.Config{ServerName: customDomain.AliasDomain},
			)

			if err != nil {
				logger.Error("cdn-tls-certificate-authorities-failure", err, lager.Data{
					"alias_domain":      customDomain.AliasDomain,
					"cloudfront_domain": customDomain.CloudFrontDomain,
				})
				continue
			}

			if _, ok := certAuthorityCounter[authority]; !ok {
				certAuthorityCounter[authority] = 0
			}

			certAuthorityCounter[authority]++
		}

		metrics := []m.Metric{}
		for authority, count := range certAuthorityCounter {
			metrics = append(metrics, m.Metric{
				Kind:  m.Gauge,
				Time:  time.Now(),
				Name:  "cdn.tls.certificates.authority",
				Value: float64(count),
				Tags: m.MetricTags{
					{Label: "certificate_authority", Value: authority},
				},
				Unit: "",
			})
		}

		return w.WriteMetrics(metrics)
	})
}
