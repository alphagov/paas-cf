package main

import (
	"fmt"
	"strings"

	"github.com/concourse/concourse/atc"
)

type resourceValidator struct {
	Name       string
	ValidateFn func(atc.ResourceConfig) []error
}

type resourceErrorCollection struct {
	ResourceName   string
	ResourceErrors []validatorErrorCollection
}

func (c resourceErrorCollection) FailureOutput() string {
	var lines []string

	for _, validatorErrors := range c.ResourceErrors {
		failureOutput := validatorErrors.FailureOutput()

		if failureOutput != "" {
			lines = append(lines, indent(failureOutput))
		}
	}

	if len(lines) == 0 {
		return ""
	}

	return strings.Join(
		append(
			[]string{fmt.Sprintf("RESOURCE %s", rColor(c.ResourceName))},
			lines...,
		),
		"\n",
	)
}

func (c resourceErrorCollection) HasErrors() bool {
	hasErrs := false
	for _, resourceErr := range c.ResourceErrors {
		hasErrs = hasErrs || resourceErr.HasErrors()
	}
	return hasErrs
}
