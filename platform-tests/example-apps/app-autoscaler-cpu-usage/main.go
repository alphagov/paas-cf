package main

import (
	"log"
	"math"
	"os"
	"time"
)

func main() {
	rawDuration := os.Getenv("DURATION")
	if rawDuration == "" {
		rawDuration = "5m"
	}

	duration, err := time.ParseDuration(rawDuration)
	if err != nil {
		log.Fatalf("Could not parse duration %s", err)
	}

	log.Printf(
		"My plan is to chill for %ds then party hard for %ds seconds, then repeat",
		int(duration.Seconds()), int(duration.Seconds()),
	)

	for {
		now := time.Now()
		secondOfHour := now.Second() + (60 * now.Minute()) // between 0 and 3600

		if weShouldChill(secondOfHour, duration) {
			chillForSomeTime(time.Now().Sub(time.Now().Truncate(duration)))
		} else {
			partyHardForSomeTime(time.Now().Sub(time.Now().Truncate(duration)))
		}
	}
}

func chillForSomeTime(duration time.Duration) {
	until := time.Now().Truncate(time.Minute).Add(duration)

	log.Printf("Going to chill until %s", until)

	time.Sleep(duration)
}

func partyHardForSomeTime(duration time.Duration) {
	until := time.Now().Truncate(time.Minute).Add(duration)
	done := make(chan struct{})

	log.Printf("Going to party hard until %s", until)

	go func() {
		for {
			select {
			case <-done:
				return
			default:
			}
		}
	}()

	time.Sleep(duration)
	done <- struct{}{}
}

func weShouldChill(secondOfHour int, duration time.Duration) bool {
	// y = sin(t * pi) is a wave with a period of 2
	// where t is the current second of the hour
	// y is positive between 0 and 1 and negative between 1 and 2

	// if sin(t * pi / seconds) is >= 0 then we should chill, else party hard
	// this ensures that all instances of the app chill and in phase

	durationSeconds := duration.Seconds()
	return math.Sin(math.Pi*float64(secondOfHour)/durationSeconds) >= 0
}
