package uaa

import "github.com/pkg/errors"

func requestError(url string) error {
	return errors.New("An unknown error occurred while calling " + url)
}

func parseError(err error, url string, body []byte) error {
	return errors.Wrapf(err, "An unknown error occurred while parsing response from %s. Response was %s", url, string(body))
}

func unknownError() error {
	return errors.New("An unknown error occurred")
}
