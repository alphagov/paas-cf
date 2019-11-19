package main

import (
	"net/url"
)

func forcePlainHTTP(uri string) (string, error) {
	u, err := url.Parse(uri)
	if err != nil {
		return "", err
	}
	u.Scheme = "http"
	return u.String(), nil
}
