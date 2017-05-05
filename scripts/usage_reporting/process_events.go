package main

import (
	"encoding/csv"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"log"
	"os"
	"time"
)

// StartedEvents can be used to track resources that have been started so
// that you can correlate their finish times.
type StartedEvents map[string]UsageEvent

func main() {
	org := flag.String("org", "", "Org GUID to report on (required)")
	flag.Parse()

	if *org == "" {
		flag.Usage()
		os.Exit(2)
	}

	processEvents(os.Stdin, *org, os.Stdout)
}

func processEvents(input io.Reader, org string, output io.Writer) {
	var (
		firstEvent, lastEvent time.Time
		startedEvents         = make(StartedEvents)
	)

	encoder := csv.NewWriter(output)
	decoder := json.NewDecoder(input)

	// Array open bracket.
	if _, err := decoder.Token(); err != nil {
		log.Fatal(err)
	}

	for decoder.More() {
		var usageEvent UsageEvent
		err := decoder.Decode(&usageEvent)
		if err != nil {
			log.Fatal(err)
		}

		// Record (roughly) the beginning and end of the reporting period.
		lastEvent = usageEvent.MetaData.CreatedAt
		if firstEvent.IsZero() {
			firstEvent = usageEvent.MetaData.CreatedAt
		}

		if usageEvent.Entity.OrgGuid != org {
			continue
		}

		switch {
		case usageEvent.Entity.AppGuid != "":
			processApp(usageEvent, startedEvents, firstEvent, encoder)
		case usageEvent.Entity.ServiceInstanceGuid != "":
			processService(usageEvent, startedEvents, firstEvent, encoder)
		}
	}

	// Array close bracket.
	if _, err := decoder.Token(); err != nil {
		log.Fatal(err)
	}

	// Fake end events for resources that are still running at the end of the
	// reporting period.
	for _, usageEvent := range startedEvents {
		usageEvent.MetaData.CreatedAt = lastEvent
		switch {
		case usageEvent.Entity.AppGuid != "":
			usageEvent.Entity.State = "STOPPED"
			processApp(usageEvent, startedEvents, firstEvent, encoder)
		case usageEvent.Entity.ServiceInstanceGuid != "":
			usageEvent.Entity.State = "DELETED"
			processService(usageEvent, startedEvents, firstEvent, encoder)
		}
	}

	encoder.Flush()
	if err := encoder.Error(); err != nil {
		log.Fatal(err)
	}
}

func processApp(
	usageEvent UsageEvent,
	startedEvents StartedEvents,
	firstEvent time.Time,
	encoder *csv.Writer,
) {
	guid := usageEvent.Entity.AppGuid
	var startTime time.Time

	switch usageEvent.Entity.State {
	case "STARTED":
		if previous, ok := startedEvents[guid]; ok {
			// change to an existing app (e.g. scale) record new start/stop
			startTime = previous.MetaData.CreatedAt
		}
		startedEvents[guid] = usageEvent
	case "STOPPED":
		if previous, ok := startedEvents[guid]; ok {
			startTime = previous.MetaData.CreatedAt
			delete(startedEvents, guid)
		} else {
			startTime = firstEvent
		}
	}

	if !startTime.IsZero() {
		encoder.Write([]string{
			usageEvent.Entity.AppName,
			usageEvent.Entity.SpaceName,
			fmt.Sprintf("%d", usageEvent.Entity.InstanceCount),
			fmt.Sprintf("%d", usageEvent.Entity.MemoryPerInstance),
			fmt.Sprintf("%.0f", usageEvent.MetaData.CreatedAt.Sub(startTime).Seconds()),
			fmt.Sprintf("%s", startTime),
		})
	}
}

func processService(
	usageEvent UsageEvent,
	startedEvents StartedEvents,
	firstEvent time.Time,
	encoder *csv.Writer,
) {
	// Ignore user provided services
	if usageEvent.Entity.ServiceInstanceType != "managed_service_instance" {
		return
	}

	guid := usageEvent.Entity.ServiceInstanceGuid
	var startTime time.Time

	switch usageEvent.Entity.State {
	case "CREATED":
		startedEvents[guid] = usageEvent
	case "UPDATED": // change of service plan is like creating a new service
		if previous, ok := startedEvents[guid]; ok {
			startTime = previous.MetaData.CreatedAt
			startedEvents[guid] = usageEvent
		} else {
			startTime = firstEvent
		}
	case "DELETED":
		if previous, ok := startedEvents[guid]; ok {
			startTime = previous.MetaData.CreatedAt
			delete(startedEvents, guid)
		} else {
			startTime = firstEvent
		}
	}

	if !startTime.IsZero() {
		encoder.Write([]string{
			usageEvent.Entity.ServiceInstanceName,
			usageEvent.Entity.SpaceName,
			usageEvent.Entity.ServiceLabel,
			usageEvent.Entity.ServicePlanName,
			fmt.Sprintf("%.0f", usageEvent.MetaData.CreatedAt.Sub(startTime).Seconds()),
			fmt.Sprintf("%s", startTime),
		})
	}
}
