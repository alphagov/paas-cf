package debug

import (
	"fmt"

	m "github.com/alphagov/paas-cf/tools/metrics/pkg/metrics"
)

// StdOutWriter writes the received metrics to the stdout
type StdOutWriter struct{}

// WriteMetrics writes the received metrics to the stdout
func (StdOutWriter) WriteMetrics(events []m.Metric) error {
	for _, event := range events {
		fmt.Println(event)
	}

	return nil
}
