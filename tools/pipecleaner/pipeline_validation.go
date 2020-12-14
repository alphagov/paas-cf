package main

import (
	"fmt"
	"strings"

	"github.com/concourse/concourse/atc"
	"github.com/concourse/concourse/atc/configvalidate"
)

type pipelineValidator struct {
	PipelineConfig atc.Config

	JobValidators      []jobValidator
	ResourceValidators []resourceValidator
	TaskValidators     []taskValidator

	ConcourseValidationErrors   []error
	ConcourseValidationWarnings []error
	JobErrors                   []jobErrorCollection
	ResourceErrors              []resourceErrorCollection
}

func (pv *pipelineValidator) HasErrors() bool {
	if len(pv.ConcourseValidationErrors) > 0 {
		return true
	}

	if len(pv.ConcourseValidationWarnings) > 0 {
		return true
	}

	for _, resourceErrors := range pv.ResourceErrors {
		for _, resourceResourceErrors := range resourceErrors.ResourceErrors {
			if len(resourceResourceErrors.ValidatorErrors) > 0 {
				return true
			}
		}
	}

	for _, jobErrors := range pv.JobErrors {
		for _, jobJobErrors := range jobErrors.JobErrors {
			if len(jobJobErrors.ValidatorErrors) > 0 {
				return true
			}
		}

		for _, resourceErrors := range jobErrors.ResourceErrors {
			for _, resourceResourceErrors := range resourceErrors.ResourceErrors {
				if len(resourceResourceErrors.ValidatorErrors) > 0 {
					return true
				}
			}
		}

		for _, taskErrors := range jobErrors.TaskErrors {
			for _, taskTaskErrors := range taskErrors.TaskErrors {
				if len(taskTaskErrors.ValidatorErrors) > 0 {
					return true
				}
			}
		}
	}

	return false
}

func (pv *pipelineValidator) FailureOutput() string {
	lines := make([]string, 0)

	if len(pv.ConcourseValidationErrors) > 0 {
		for _, err := range pv.ConcourseValidationErrors {
			lines = append(lines, indent(fmt.Sprintf("CONCOURSE %s", err)))
		}
		return strings.Join(lines, "\n")
	}

	if len(pv.ConcourseValidationWarnings) > 0 {
		for _, err := range pv.ConcourseValidationWarnings {
			lines = append(lines, indent(fmt.Sprintf("CONCOURSE %s", err)))
		}
	}

	for _, resourceErrors := range pv.ResourceErrors {
		failureOutput := resourceErrors.FailureOutput()
		if failureOutput != "" {
			lines = append(lines, indent(failureOutput))
		}
	}

	for _, jobErrors := range pv.JobErrors {
		failureOutput := jobErrors.FailureOutput()
		if failureOutput != "" {
			lines = append(lines, indent(failureOutput))
		}
	}

	return strings.Join(lines, "\n")
}

func (pv *pipelineValidator) Validate() {
	warnings, errors := configvalidate.Validate(pv.PipelineConfig)

	for _, warning := range warnings {
		pv.ConcourseValidationWarnings = append(
			pv.ConcourseValidationWarnings,
			fmt.Errorf("atc validate warning %s: %s", warning.Type, warning.Message),
		)
	}

	for _, err := range errors {
		pv.ConcourseValidationErrors = append(
			pv.ConcourseValidationErrors,
			fmt.Errorf(err),
		)
	}

	if len(pv.ConcourseValidationErrors) > 0 {
		return
	}

	pv.ValidateResources()
	pv.ValidateJobs()
}

func (pv *pipelineValidator) ValidateResources() {
	errors := make([]resourceErrorCollection, 0)

	for _, resource := range pv.PipelineConfig.Resources {
		errColl := resourceErrorCollection{ResourceName: resource.Name}

		for _, validator := range pv.ResourceValidators {
			errColl.ResourceErrors = append(errColl.ResourceErrors,
				validatorErrorCollection{
					ValidatorName:   validator.Name,
					ValidatorErrors: validator.ValidateFn(resource),
				},
			)
		}

		errors = append(errors, errColl)
	}

	pv.ResourceErrors = errors
}

func (pv *pipelineValidator) ValidateJobs() {
	errors := make([]jobErrorCollection, 0)

	for _, job := range pv.PipelineConfig.Jobs {
		errColl := jobErrorCollection{JobName: job.Name}

		for _, validator := range pv.JobValidators {
			errColl.JobErrors = append(errColl.JobErrors, validatorErrorCollection{
				ValidatorName:   validator.Name,
				ValidatorErrors: validator.ValidateFn(job),
			})
		}

		job.StepConfig().Visit(atc.StepRecursor{
			OnTask: func(step *atc.TaskStep) error {
				if step.Config == nil {
					return nil
				}

				errColl.TaskErrors = append(errColl.TaskErrors, taskErrorCollection{
					TaskName:   step.Name,
					TaskErrors: pv.ValidateTask(*step.Config, step.Params),
				})

				return nil
			},
		})

		errors = append(errors, errColl)
	}

	pv.JobErrors = errors
}

func (pv *pipelineValidator) ValidateTask(
	taskConfig atc.TaskConfig,
	params atc.TaskEnv,
) []validatorErrorCollection {
	errCollections := make([]validatorErrorCollection, 0)

	for _, validator := range pv.TaskValidators {
		errCollections = append(errCollections, validatorErrorCollection{
			ValidatorName:   validator.Name,
			ValidatorErrors: validator.ValidateFn(taskConfig, params),
		})
	}

	return errCollections
}
