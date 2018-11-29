package main

import "fmt"

// StdOutWriter writes the received metrics to the stdout
type StdOutWriter struct{}

// WriteMetrics writes the received metrics to the stdout
func (StdOutWriter) WriteMetrics(events []Metric) error {
	for _, event := range events {
		fmt.Println(event)
	}

	return nil
}
