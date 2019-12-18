package main

import (
	"fmt"
	"strings"

	"github.com/concourse/concourse/atc"
)

type jobValidator struct {
	Name       string
	ValidateFn func(atc.JobConfig) []error
}

type jobErrorCollection struct {
	JobName string

	JobErrors      []validatorErrorCollection
	ResourceErrors []resourceErrorCollection
	TaskErrors     []taskErrorCollection
}

func (c jobErrorCollection) FailureOutput() string {
	var lines []string

	for _, jobErrors := range c.JobErrors {
		failureOutput := jobErrors.FailureOutput()
		if failureOutput != "" {
			lines = append(lines, indent(failureOutput))
		}
	}

	for _, resourceErrors := range c.ResourceErrors {
		failureOutput := resourceErrors.FailureOutput()
		if failureOutput != "" {
			lines = append(lines, indent(failureOutput))
		}
	}

	for _, taskErrors := range c.TaskErrors {
		failureOutput := taskErrors.FailureOutput()
		if failureOutput != "" {
			lines = append(lines, indent(failureOutput))
		}
	}

	if len(lines) == 0 {
		return ""
	}

	title := fmt.Sprintf("JOB %s", rColor(c.JobName))
	return strings.Join(append([]string{title}, lines...), "\n")
}
