package retryhttp

import (
	"time"

	"github.com/cenkalti/backoff"
)

//go:generate counterfeiter . BackOff

type BackOff interface {
	NextBackOff() time.Duration
	GetElapsedTime() time.Duration
	Reset()
}

//go:generate counterfeiter . BackOffFactory

type BackOffFactory interface {
	NewBackOff() BackOff
}

type exponentialBackOffFactory struct {
	timeout time.Duration
}

func NewExponentialBackOffFactory(timeout time.Duration) BackOffFactory {
	return &exponentialBackOffFactory{
		timeout: timeout,
	}
}

func (f *exponentialBackOffFactory) NewBackOff() BackOff {
	return &backoff.ExponentialBackOff{
		InitialInterval:     1 * time.Second,
		RandomizationFactor: 0,
		Multiplier:          2,
		MaxInterval:         16 * time.Second,
		MaxElapsedTime:      f.timeout,
		Clock:               backoff.SystemClock,
	}
}
