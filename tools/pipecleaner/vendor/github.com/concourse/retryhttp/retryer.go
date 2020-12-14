package retryhttp

import (
	"errors"
	"net"
	"strings"
	"syscall"
)

//go:generate counterfeiter . Retryer

type Retryer interface {
	IsRetryable(err error) bool
}

type DefaultRetryer struct{}

func (r *DefaultRetryer) IsRetryable(err error) bool {
	if neterr, ok := err.(net.Error); ok {
		if neterr.Temporary() {
			return true
		}
	}

	s := err.Error()
	for _, retryableError := range defaultRetryableErrors {
		if strings.HasSuffix(
			strings.ToLower(s),
			strings.ToLower(retryableError.Error())) {
			return true
		}
	}

	return false
}

var defaultRetryableErrors = []error{
	syscall.ECONNREFUSED, // "connection refused"
	syscall.ECONNRESET,   // "connection reset by peer"
	syscall.ETIMEDOUT,    // "operation timed out"
	errors.New("i/o timeout"),
	errors.New("no such host"),
	errors.New("handshake failure"),
	errors.New("handshake timeout"),
	errors.New("timeout awaiting response headers"),
	errors.New("unexpected EOF"),
	errors.New("unexpected EOF reading trailer"),
}
