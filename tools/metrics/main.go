package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/alphagov/paas-cf/tools/metrics/pingdumb"
	"github.com/alphagov/paas-cf/tools/metrics/tlscheck"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/pkg/errors"

	"code.cloudfoundry.org/lager"
)

func handler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Cache-Control", "max-age=0,no-store,no-cache")
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(struct {
		OK bool
	}{
		OK: true,
	})
}

func server() error {
	addr := ":" + os.Getenv("PORT")
	http.HandleFunc("/", handler)
	return http.ListenAndServe(addr, nil)
}

func Main() error {
	// serve something
	go server()
	// create a logger
	logger := lager.NewLogger("metrics")
	logLevel := lager.INFO
	if os.Getenv("LOG_LEVEL") == "0" {
		logLevel = lager.DEBUG
	}
	logger.RegisterSink(lager.NewWriterSink(os.Stdout, logLevel))
	// create a client
	c, err := NewClient(ClientConfig{
		ApiAddress:        os.Getenv("CF_API_ADDRESS"),
		ClientID:          os.Getenv("CF_CLIENT_ID"),
		ClientSecret:      os.Getenv("CF_CLIENT_SECRET"),
		SkipSslValidation: os.Getenv("CF_SKIP_SSL_VALIDATION") == "true",
		Logger:            logger,
	})
	if err != nil {
		return errors.Wrap(err, "failed to connect to cloud foundry api")
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
	cfs := NewCloudFrontService(sess)
	tlsChecker := &tlscheck.TLSChecker{}

	ecs := NewElasticacheService(sess)

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
	}
	for _, addr := range strings.Split(os.Getenv("TLS_DOMAINS"), ",") {
		gauges = append(gauges, TLSValidityGauge(logger, tlsChecker, strings.TrimSpace(addr), 15*time.Minute))
	}
	metrics := NewMultiMetricReader(gauges...)
	defer metrics.Close()
	// create a reporter
	reporter := NewDatadogReporter(DatadogConfig{
		ApiKey:        os.Getenv("DATADOG_API_KEY"),
		AppKey:        os.Getenv("DATADOG_APP_KEY"),
		Logger:        logger,
		BatchSize:     100,
		BatchInterval: 60 * time.Second,
		Tags:          []string{"deploy_env:" + os.Getenv("DEPLOY_ENV")},
	})
	// copy all the metrics to the reporter
	for {
		if err := CopyMetrics(reporter, metrics); err != nil {
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
