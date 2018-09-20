package cfclient

//go:generate go run gen_error.go

import (
	"fmt"
)

type CloudFoundryErrors struct {
	Errors []CloudFoundryError `json:"errors"`
}

func (cfErrs CloudFoundryErrors) Error() string {
	err := ""

	for _, cfErr := range cfErrs.Errors {
		err += fmt.Sprintf("%s\n", cfErr)
	}

	return err
}

type CloudFoundryError struct {
	Code        int    `json:"code"`
	ErrorCode   string `json:"error_code"`
	Description string `json:"description"`
}

func (cfErr CloudFoundryError) Error() string {
	return fmt.Sprintf("cfclient error (%s|%d): %s", cfErr.ErrorCode, cfErr.Code, cfErr.Description)
}

type CloudFoundryHTTPError struct {
	StatusCode int
	Status     string
	Body       []byte
}

func (e CloudFoundryHTTPError) Error() string {
	return fmt.Sprintf("cfclient: HTTP error (%d): %s", e.StatusCode, e.Status)
}
