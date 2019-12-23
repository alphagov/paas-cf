package main

import (
	"fmt"
	"regexp"

	"github.com/concourse/concourse/atc"
)

var (
	secretsResourceValidator = resourceValidator{
		Name:       "secrets",
		ValidateFn: secretsCheckResource,
	}

	secretsTaskValidator = taskValidator{
		Name:       "secrets",
		ValidateFn: secretsCheckTask,
	}

	containsKeyRegexp    = regexp.MustCompile("(?i)_KEY")
	containsPassRegexp   = regexp.MustCompile("(?i)(^PASSWORD)|(_PASS)")
	containsSecretRegexp = regexp.MustCompile("(?i)(^SECRET_)|(_SECRET)")

	publicKeyRegexp = regexp.MustCompile("(?i)PUBLIC_KEY")

	absFilepathRegexp      = regexp.MustCompile("^/")
	relativeFilepathRegexp = regexp.MustCompile("^./")
	parentFilepathRegexp   = regexp.MustCompile("^../")
)

func secretsCheckResource(resource atc.ResourceConfig) []error {
	errors := make([]error, 0)

	for paramName, paramVal := range resource.Source {
		if varLikelyRefersToSecret(paramName) &&
			!concourseVarRegexp.MatchString(fmt.Sprintf("%s", paramVal)) {
			errors = append(errors,
				fmt.Errorf(
					"Resource source param %s is not interpolated and may leak credentials",
					rColor(paramName),
				),
			)
		}
	}

	return errors
}

func secretsCheckTask(task atc.TaskConfig, params atc.Params) []error {
	errors := make([]error, 0)

	for varName, varVal := range task.Params {
		if varLikelyRefersToSecret(varName) &&
			varVal != "" &&
			!varLikelyRefersToPublicKey(varName) &&
			!varLikelyIsAFilepath(varVal) &&
			!concourseVarRegexp.MatchString(varVal) {
			errors = append(errors,
				fmt.Errorf(
					"Task config param %s is not interpolated and may leak credentials",
					rColor(varName),
				),
			)
		}
	}

	for varName, varVal := range params {
		if varLikelyRefersToSecret(varName) &&
			!concourseVarRegexp.MatchString(fmt.Sprintf("%s", varVal)) {
			errors = append(errors,
				fmt.Errorf(
					"Task config param %s is not interpolated and may leak credentials",
					rColor(varName),
				),
			)
		}
	}

	return errors
}

func varLikelyRefersToPublicKey(varName string) bool {
	return publicKeyRegexp.MatchString(varName)
}

func varLikelyRefersToSecret(varName string) bool {
	return containsKeyRegexp.MatchString(varName) ||
		containsPassRegexp.MatchString(varName) ||
		containsSecretRegexp.MatchString(varName)
}

func varLikelyIsAFilepath(varVal string) bool {
	return absFilepathRegexp.MatchString(varVal) ||
		relativeFilepathRegexp.MatchString(varVal) ||
		parentFilepathRegexp.MatchString(varVal)
}
