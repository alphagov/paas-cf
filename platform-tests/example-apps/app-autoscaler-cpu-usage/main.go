package main

import (
	"log"
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
		"My plan is to chill for %s then party hard for %s, then repeat",
		duration, duration,
	)

	for {
		// using a fixed "now" makes it easier to reason about behaviour
		// and removes an amount of nondeterminism
		uniformNow := time.Now()
		party, timeRemaining := shouldWePartyAndForHowLong(uniformNow, duration)

		if party {
			partyHardForSomeTime(timeRemaining)
		} else {
			chillForSomeTime(timeRemaining)
		}
	}
}

func chillForSomeTime(duration time.Duration) {
	until := time.Now().Truncate(time.Millisecond).Add(duration)

	log.Printf("Going to chill until %s", until)

	time.Sleep(duration)
}

func partyHardForSomeTime(duration time.Duration) {
	until := time.Now().Truncate(time.Millisecond).Add(duration)
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

func shouldWePartyAndForHowLong(tNow time.Time, period time.Duration) (bool, time.Duration) {
	// this has to be calculated based on absolute time so that different
	// instances are in sync with each other, meaning we can't use
	// go's monotonic clock arithmetic, so in theory this isn't totally
	// clock-slew-safe, but i can live with that.

	// whether we should party is just whether the time tNow divided by the
	// period is odd
	shouldWe := (tNow.UnixMilli() / int64(period.Milliseconds())) % 2 != 0

	// the time remaining is the period minus the remainder of that division
	timeRemaining := period - time.Duration(float64(tNow.UnixMilli() % int64(period.Milliseconds())) * float64(time.Millisecond))

	return shouldWe, timeRemaining
}
