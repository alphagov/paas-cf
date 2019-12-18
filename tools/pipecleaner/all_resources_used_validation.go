package main

import (
	"fmt"

	"github.com/concourse/concourse/atc"
)

var (
	allResourcesUsedValidator = jobValidator{
		Name:       "all-resources-used",
		ValidateFn: checkAllResourcesUsed,
	}
)

func checkAllResourcesUsed(job atc.JobConfig) []error {
	errors := make([]error, 0)

	jobContainsATaskFile := false // if we see "file: true" we cannot check this
	resourcesPresent := make(map[string]bool, 0)

	for _, getStep := range job.Inputs() {
		if getStep.Trigger {
			resourcesPresent[getStep.Name] = true
			continue
		}

		if len(getStep.Passed) > 0 {
			resourcesPresent[getStep.Name] = true
			continue
		}

		resourcesPresent[getStep.Name] = false
	}

	for _, putStep := range job.Outputs() {
		resourcesPresent[putStep.Name] = true
	}

	for _, step := range job.Plans() {
		if step.ImageArtifactName != "" {
			resourcesPresent[step.ImageArtifactName] = true
		}

		if step.TaskConfig != nil {
			for _, input := range step.TaskConfig.Inputs {
				resourcesPresent[input.Name] = true
			}

			for _, output := range step.TaskConfig.Outputs {
				resourcesPresent[output.Name] = true
			}
		}

		if step.TaskConfigPath != "" {
			jobContainsATaskFile = true
		}
	}

	if jobContainsATaskFile {
		return errors
	}

	for resourceName, resourceIsUsed := range resourcesPresent {
		if !resourceIsUsed {
			errors = append(
				errors,
				fmt.Errorf("Resource %s is never used", rColor(resourceName)),
			)
		}
	}

	return errors
}
