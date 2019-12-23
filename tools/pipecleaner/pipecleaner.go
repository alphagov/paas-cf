package main

import (
	"flag"
	"fmt"
	"os"
	"strings"

	"github.com/concourse/concourse/atc"
)

var (
	allResourcesUsed bool
	rubocop          bool
	shellcheck       bool
	secrets          bool
)

func main() {
	flag.BoolVar(
		&allResourcesUsed, "all-resources-used", true,
		"Enable/disable all-resources-used validator",
	)

	flag.BoolVar(
		&rubocop, "rubocop", true,
		"Enable/disable rubocop validator",
	)

	flag.BoolVar(
		&shellcheck, "shellcheck", true,
		"Enable/disable shellcheck validator",
	)

	flag.BoolVar(
		&secrets, "secrets", true,
		"Enable/disable secrets validator",
	)
	flag.Parse()

	args := flag.Args()
	if len(args) == 0 {
		fmt.Println("pipecleaner")
		fmt.Println()
		fmt.Println("pipecleaner is a tool to analyse concourse pipelines/tasks")
		fmt.Println()
		fmt.Println("usage: pipecleaner [flags] pipeline1.yml [pipelineN.yml...]")
		fmt.Println()
		fmt.Println("flags:")
		flag.PrintDefaults()
		os.Exit(2)
	}

	jobValidators := make([]jobValidator, 0)
	resourceValidators := make([]resourceValidator, 0)
	taskValidators := make([]taskValidator, 0)

	if allResourcesUsed {
		jobValidators = append(jobValidators, allResourcesUsedValidator)
	}

	if rubocop {
		taskValidators = append(taskValidators, rubocopValidator)
	}

	if shellcheck {
		taskValidators = append(taskValidators, shellcheckValidator)
	}

	if secrets {
		resourceValidators = append(resourceValidators, secretsResourceValidator)
		taskValidators = append(taskValidators, secretsTaskValidator)
	}

	encounteredErrors := false

	for fileIndex, fname := range args {
		if fileIndex > 0 {
			fmt.Println()
		}

		pipelineConfig, taskConfig, err := ParsePipelineOrTask(fname)

		if err != nil {
			encounteredErrors = true
			fmt.Printf("FILE %s\n", rColor(fname))
			fmt.Println(indent(err))
			continue
		}

		if pipelineConfig != nil {
			validator := pipelineValidator{
				PipelineConfig: *pipelineConfig,

				JobValidators:      jobValidators,
				ResourceValidators: resourceValidators,
				TaskValidators:     taskValidators,
			}

			validator.Validate()

			if validator.HasErrors() {
				encounteredErrors = true
				fmt.Printf("FILE %s (%s)\n", rColor(fname), yColor("pipeline"))
				fmt.Println(validator.FailureOutput())
			} else {
				fmt.Printf("FILE %s (%s)\n", gColor(fname), yColor("pipeline"))
			}
		}

		if taskConfig != nil {
			taskErrors := make([]validatorErrorCollection, 0)

			for _, validator := range taskValidators {
				taskErrors = append(taskErrors, validatorErrorCollection{
					ValidatorName:   validator.Name,
					ValidatorErrors: validator.ValidateFn(*taskConfig, atc.Params{}),
				})
			}

			fileHasErrors := false
			for _, validatorErrors := range taskErrors {
				if len(validatorErrors.ValidatorErrors) > 0 {
					fileHasErrors = true
				}
			}

			if fileHasErrors {
				encounteredErrors = true
				fmt.Printf("FILE %s (%s)\n", rColor(fname), yColor("task"))
				for _, validatorErrors := range taskErrors {
					errOutput := validatorErrors.FailureOutput()
					if errOutput != "" {
						fmt.Println(indent(errOutput))
					}
				}
			} else {
				fmt.Printf("FILE %s (%s)\n", gColor(fname), yColor("task"))
			}
		}
	}

	if encounteredErrors {
		os.Exit(10)
	}

	os.Exit(0)
}

func shouldVarBeInterpolated(varname string) bool {
	if strings.Contains(strings.ToUpper(varname), "KEY") ||
		strings.Contains(strings.ToUpper(varname), "SECRET") {
		return true
	}
	return false
}
