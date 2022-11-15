package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/alphagov/paas-cf/tools/metrics/pkg/health"
	"github.com/alphagov/paas-cf/tools/metrics/pkg/logit"
	"github.com/alphagov/paas-cf/tools/metrics/pkg/shield"

	"github.com/aws/aws-sdk-go/aws"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"

	"github.com/alphagov/paas-cf/tools/metrics/pkg/pingdumb"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/costexplorer"
	"github.com/pkg/errors"

	"code.cloudfoundry.org/lager"

	"github.com/alphagov/paas-cf/tools/metrics/pkg/aiven"
	"github.com/alphagov/paas-cf/tools/metrics/pkg/cloudfront"
	"github.com/alphagov/paas-cf/tools/metrics/pkg/cloudwatch"
	"github.com/alphagov/paas-cf/tools/metrics/pkg/debug"
	"github.com/alphagov/paas-cf/tools/metrics/pkg/elasticache"
	m "github.com/alphagov/paas-cf/tools/metrics/pkg/metrics"
	promrep "github.com/alphagov/paas-cf/tools/metrics/pkg/prometheus_reporter"
	"github.com/alphagov/paas-cf/tools/metrics/pkg/rds"
	"github.com/alphagov/paas-cf/tools/metrics/pkg/s3"
	"github.com/alphagov/paas-cf/tools/metrics/pkg/servicequotas"
	"github.com/alphagov/paas-cf/tools/metrics/pkg/tlscheck"
)

func getHTTPPort() int {
	portStr := os.Getenv("PORT")
	if portStr != "" {
		port, err := strconv.Atoi(portStr)
		if err != nil {
			log.Fatalln("PORT is invalid")
			return 0
		}
		return port
	}

	return 8080
}

func runHTTPServer(port int, metricsHandler http.Handler) {
	addr := fmt.Sprintf(":%d", port)

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Cache-Control", "max-age=0,no-store,no-cache")
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(struct {
			OK bool
		}{
			OK: true,
		})
	})

	http.Handle("/metrics", metricsHandler)

	go http.ListenAndServe(addr, nil)
}

func Main() error {
	prometheusRegistry := prometheus.NewRegistry()
	prometheusHandler := promhttp.HandlerFor(
		prometheusRegistry,
		promhttp.HandlerOpts{},
	)

	runHTTPServer(getHTTPPort(), prometheusHandler)

	// create a logger
	logger := lager.NewLogger("metrics")
	logLevel := lager.INFO
	if os.Getenv("LOG_LEVEL") == "0" {
		logLevel = lager.DEBUG
	}
	logger.RegisterSink(lager.NewWriterSink(os.Stdout, logLevel))

	// create a client ("github.com/alphagov/paas-cf/tools/metrics/client.go Client")
	cfConfig := ClientConfig{
		ApiAddress:   os.Getenv("CF_API_ADDRESS"),
		ClientID:     os.Getenv("CF_CLIENT_ID"),
		ClientSecret: os.Getenv("CF_CLIENT_SECRET"),
		Logger:       logger,
	}
	c, err := NewClient(cfConfig)
	if err != nil {
		return errors.Wrap(err, "failed to connect to cloud foundry api")
	}

	// create a CloudFoundry client instance
	cfAPI, err := NewCFClient(cfConfig)
	if err != nil {
		return errors.Wrap(err, "failed to connect to cloud foundry api")
	}

	uaaCfg := UAAClientConfig{
		Endpoint:     os.Getenv("UAA_ENDPOINT"),
		ClientID:     os.Getenv("CF_CLIENT_ID"),
		ClientSecret: os.Getenv("CF_CLIENT_SECRET"),
	}

	a, err := aiven.NewClient(
		os.Getenv("AIVEN_PROJECT"),
		os.Getenv("AIVEN_API_TOKEN"),
	)
	if err != nil {
		return errors.Wrap(err, "failed to get Aiven connection data")
	}

	sess, err := session.NewSession()
	if err != nil {
		return errors.Wrap(err, "failed to connect to AWS API")
	}
	awsRegion := *sess.Config.Region
	if awsRegion != "eu-west-1" && awsRegion != "eu-west-2" {
		return fmt.Errorf("unexpected aws region %s", awsRegion)
	}

	cfs := cloudfront.NewService(sess)
	tlsChecker := &tlscheck.TLSChecker{}

	ecs := elasticache.NewService(sess)
	s3 := s3.NewService(sess)

	usEast1Sess, err := session.NewSession(&aws.Config{Region: aws.String("us-east-1")})
	if err != nil {
		return errors.Wrap(err, "failed to connect to AWS API in US East 1")
	}
	cloudWatch := cloudwatch.NewService(usEast1Sess, logger)

	costExplorer := costexplorer.New(sess)

	serviceQuotas := servicequotas.NewService(sess)

	rdsService := rds.NewService(sess)

	logitClient, err := logit.NewService(
		logger,
		os.Getenv("LOGIT_ELASTICSEARCH_URL"),
		os.Getenv("LOGIT_ELASTICSEARCH_API_KEY"),
	)
	if err != nil {
		return errors.Wrap(err, "failed to create logit client")
	}

	healthService := health.NewService(sess)
	shieldService := shield.NewService(sess)

	// Combine all metrics into single stream
	gauges := []m.MetricReader{
		AppCountGauge(c, 5*time.Minute),                 // poll number of apps
		ServiceCountGauge(c, 5*time.Minute),             // poll number of provisioned services
		OrgCountGauge(c, 5*time.Minute),                 // poll number of orgs
		SpaceCountGauge(c, 5*time.Minute),               // poll number of spaces
		UserCountGauge(c, 5*time.Minute),                // poll number of users
		QuotaGauge(c, 5*time.Minute),                    // poll quota usage
		AivenCostGauge(a, 5*time.Minute),                // poll aiven cost
		EventCountGauge(c, "app.crash", 10*time.Minute), // count number of times an event is seen within the interval
		ELBNodeFailureCountGauge(logger, pingdumb.ReportConfig{
			Target:  os.Getenv("ELB_ADDRESS"),
			Timeout: 5 * time.Second,
		}, 30*time.Second),
		CDNTLSValidityGauge(logger, tlsChecker, cfs, 1*time.Hour),
		CDNTLSCertificateAuthorityGauge(logger, tlsChecker, cfs, 1*time.Hour),
		ElasticacheInstancesGauge(logger, ecs, cfAPI, 5*time.Minute),
		ElasticacheUpdatesGauge(logger, ecs, cfAPI, 5*time.Minute),
		S3BucketsGauge(logger, s3, 1*time.Hour),
		CustomDomainCDNMetricsCollector(logger, cfs, cloudWatch, 10*time.Minute),
		AWSCostExplorerGauge(logger, awsRegion, costExplorer, 6*time.Hour),
		UAAGauges(logger, &uaaCfg, 5*time.Minute),
		BillingCostsGauge(logger, os.Getenv("BILLING_ENDPOINT"), 15*time.Minute),
		BillingCollectorPerformanceGauge(logger, 15*time.Minute, logitClient),
		BillingApiPerformanceGauge(logger, 15*time.Minute, logitClient),
		RDSDBInstancesGauge(logger, rdsService, serviceQuotas, 15*time.Minute),
		RDSDBManualSnapshotsGauge(logger, rdsService, serviceQuotas, 15*time.Minute),
		AWSHealthEventsGauge(logger, awsRegion, healthService, 15*time.Minute),
		ShieldOngoingAttacksGauge(logger, shieldService, 5*time.Minute),
		CloudfrontDistributionInstancesGauge(logger, cfs, 15*time.Minute),
	}
	for _, addr := range strings.Split(os.Getenv("TLS_DOMAINS"), ",") {
		gauges = append(gauges, TLSValidityGauge(logger, tlsChecker, strings.TrimSpace(addr), 15*time.Minute))
	}
	metrics := m.NewMultiMetricReader(gauges...)
	defer metrics.Close()

	prometheusReporter := promrep.NewPrometheusReporter(prometheusRegistry)

	multiWriter := m.NewMultiMetricWriter(prometheusReporter)

	if os.Getenv("DEBUG") == "1" {
		multiWriter.AddWriter(debug.StdOutWriter{})
	}

	for {
		if err := m.CopyMetrics(multiWriter, metrics); err != nil {
			logger.Error("error-streaming-metrics", err)
		}
	}
}

func main() {
	if err := Main(); err != nil {
		log.Fatal(err)
	}
	fmt.Println("shutdown gracefully")
}
