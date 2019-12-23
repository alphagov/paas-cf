package main

import (
	"fmt"
	"strings"
)

type validatorErrorCollection struct {
	ValidatorName   string
	ValidatorErrors []error
}

func (c validatorErrorCollection) FailureOutput() string {
	if len(c.ValidatorErrors) == 0 {
		return ""
	}

	lines := []string{
		strings.ToUpper(c.ValidatorName),
	}

	for _, err := range c.ValidatorErrors {
		lines = append(lines, indent(fmt.Sprintf("%s", err)))
	}

	return strings.Join(lines, "\n")
}

func (c validatorErrorCollection) HasErrors() bool {
	return len(c.ValidatorErrors) > 0
}
