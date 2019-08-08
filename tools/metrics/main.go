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

	"github.com/aws/aws-sdk-go/aws"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"

	"github.com/alphagov/paas-cf/tools/metrics/pingdumb"
	"github.com/alphagov/paas-cf/tools/metrics/tlscheck"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/costexplorer"
	"github.com/pkg/errors"

	"code.cloudfoundry.org/lager"
)

func initPrometheus() (*prometheus.Registry, http.Handler) {
	registry := prometheus.NewRegistry()
	handler := promhttp.HandlerFor(registry, promhttp.HandlerOpts{})
	return registry, handler
}

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
	prometheusRegistry, prometheusHandler := initPrometheus()

	runHTTPServer(getHTTPPort(), prometheusHandler)

	// create a logger
	logger := lager.NewLogger("metrics")
	logLevel := lager.INFO
	if os.Getenv("LOG_LEVEL") == "0" {
		logLevel = lager.DEBUG
	}
	logger.RegisterSink(lager.NewWriterSink(os.Stdout, logLevel))

	// create a client
	c, err := NewClient(ClientConfig{
		ApiAddress:   os.Getenv("CF_API_ADDRESS"),
		ClientID:     os.Getenv("CF_CLIENT_ID"),
		ClientSecret: os.Getenv("CF_CLIENT_SECRET"),
		Logger:       logger,
	})
	if err != nil {
		return errors.Wrap(err, "failed to connect to cloud foundry api")
	}

	uaaCfg := UAAClientConfig{
		Endpoint:     os.Getenv("UAA_ENDPOINT"),
		ClientID:     os.Getenv("CF_CLIENT_ID"),
		ClientSecret: os.Getenv("CF_CLIENT_SECRET"),
	}

	a, err := NewAivenClient(
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

	cfs := NewCloudFrontService(sess)
	tlsChecker := &tlscheck.TLSChecker{}

	ecs := NewElasticacheService(sess)
	s3 := NewS3Service(sess)

	usEast1Sess, err := session.NewSession(&aws.Config{Region: aws.String("us-east-1")})
	if err != nil {
		return errors.Wrap(err, "failed to connect to AWS API in US East 1")
	}
	cloudWatch := NewCloudWatchService(usEast1Sess, logger)

	costExplorer := costexplorer.New(sess)

	// Combine all metrics into single stream
	gauges := []MetricReader{
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
		ElasticCacheInstancesGauge(logger, ecs, 5*time.Minute),
		S3BucketsGauge(logger, s3, 1*time.Hour),
		CustomDomainCDNMetricsCollector(logger, cfs, cloudWatch, 10*time.Minute),
		AWSCostExplorerGauge(logger, awsRegion, costExplorer, 6*time.Hour),
		UAAGauges(logger, &uaaCfg, 5*time.Minute),
		BillingCostsGauge(logger, os.Getenv("COSTS_ENDPOINT"), 15*time.Minute),
	}
	for _, addr := range strings.Split(os.Getenv("TLS_DOMAINS"), ",") {
		gauges = append(gauges, TLSValidityGauge(logger, tlsChecker, strings.TrimSpace(addr), 15*time.Minute))
	}
	metrics := NewMultiMetricReader(gauges...)
	defer metrics.Close()

	prometheusReporter := NewPrometheusReporter(prometheusRegistry)

	multiWriter := NewMultiMetricWriter(
		prometheusReporter,
	)

	if os.Getenv("DEBUG") == "1" {
		multiWriter.AddWriter(StdOutWriter{})
	}

	for {
		if err := CopyMetrics(multiWriter, metrics); err != nil {
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
