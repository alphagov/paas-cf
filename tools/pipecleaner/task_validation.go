package main

import (
	"fmt"
	"strings"

	"github.com/concourse/concourse/atc"
)

type taskValidator struct {
	Name       string
	ValidateFn func(atc.TaskConfig, atc.TaskEnv) []error
}

type taskErrorCollection struct {
	TaskName   string
	TaskErrors []validatorErrorCollection
}

func (c taskErrorCollection) FailureOutput() string {
	var lines []string

	for _, validatorErrors := range c.TaskErrors {
		failureOutput := validatorErrors.FailureOutput()

		if failureOutput != "" {
			lines = append(lines, indent(failureOutput))
		}
	}

	if len(lines) == 0 {
		return ""
	}

	return strings.Join(
		append([]string{fmt.Sprintf("TASK %s", rColor(c.TaskName))}, lines...),
		"\n",
	)
}

func (c taskErrorCollection) HasErrors() bool {
	hasErrs := false
	for _, taskErr := range c.TaskErrors {
		hasErrs = hasErrs || taskErr.HasErrors()
	}
	return hasErrs
}
