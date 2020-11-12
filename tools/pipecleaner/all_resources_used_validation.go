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

	jobContainsATaskFile := false   // if we see "file: true" we cannot check this
	jobContainsSetPipeline := false // if we see set_pipeline we cannot check this
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

	job.StepConfig().Visit(atc.StepRecursor{
		OnTask: func(step *atc.TaskStep) error {
			if step.Config != nil {

				if step.ImageArtifactName != "" {
					resourcesPresent[step.ImageArtifactName] = true
				}

				for _, input := range step.Config.Inputs {
					resourcesPresent[input.Name] = true
				}

				for _, output := range step.Config.Outputs {
					resourcesPresent[output.Name] = true
				}
			}

			if step.ConfigPath != "" {
				jobContainsATaskFile = true
			}

			return nil
		},
		OnSetPipeline: func(step *atc.SetPipelineStep) error {
			jobContainsSetPipeline = true
			return nil
		},
	})

	if jobContainsATaskFile {
		return errors
	}

	if jobContainsSetPipeline {
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
