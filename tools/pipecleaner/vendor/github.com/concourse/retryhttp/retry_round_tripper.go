package retryhttp

import (
	"io"
	"net/http"
	"time"

	"github.com/cenkalti/backoff"

	"code.cloudfoundry.org/lager"
)

//go:generate counterfeiter . Sleeper

type Sleeper interface {
	Sleep(time.Duration)
}

//go:generate counterfeiter . RoundTripper

type RoundTripper interface {
	RoundTrip(request *http.Request) (*http.Response, error)
}

type RetryRoundTripper struct {
	Logger         lager.Logger
	BackOffFactory BackOffFactory
	RoundTripper   RoundTripper
	Retryer        Retryer
}

type RetryReadCloser struct {
	io.ReadCloser
	IsRead bool
}

func (rrc *RetryReadCloser) Read(p []byte) (n int, err error) {
	rrc.IsRead = true
	return rrc.ReadCloser.Read(p)
}

func (d *RetryRoundTripper) RoundTrip(request *http.Request) (*http.Response, error) {
	retryReadCloser := &RetryReadCloser{request.Body, false}

	if request.Body != nil {
		request.Body = retryReadCloser
	}

	var response *http.Response
	var err error
	var failedAttempts uint

	backOff := d.BackOffFactory.NewBackOff()

	backoff.Retry(func() error {
		response, err = d.RoundTripper.RoundTrip(request)
		if err != nil && !retryReadCloser.IsRead && d.Retryer.IsRetryable(err) {
			failedAttempts++
			d.Logger.Info("retrying", lager.Data{
				"failed-attempts": failedAttempts,
				"ran-for":         backOff.GetElapsedTime().String(),
				"error":           err.Error(),
			})
			return err
		}

		return nil
	}, backOff)

	return response, err
}
