package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"os/exec"
	"strings"

	"github.com/concourse/concourse/atc"
)

var (
	shellcheckValidator = taskValidator{
		Name:       "shellcheck",
		ValidateFn: shellcheckTask,
	}
)

type shellcheckResult struct {
	Line    int    `json:"line"`
	Column  int    `json:"column"`
	Code    int    `json:"code"`
	Message string `json:"message"`
}

func canShellcheckDialect(dialect string) bool {
	switch dialect {
	case "sh", "ksh", "dash", "ash", "bash":
		return true
	}
	return false
}

func shellcheckTask(task atc.TaskConfig, params atc.TaskEnv) []error {
	errors := make([]error, 0)

	dialect := task.Run.Path
	if !canShellcheckDialect(dialect) {
		return errors
	}

	linesPrepended := 0
	script := ""
	for _, arg := range task.Run.Args {
		if strings.HasPrefix(arg, "-") && strings.Contains(arg, "c") {
			for _, r := range []rune(arg) {
				if r != '-' && r != 'c' {
					script += fmt.Sprintf("set -%s\n", string(r))
					linesPrepended++
				}
			}
			break
		}

		script += fmt.Sprintf("set %s\n", arg)
		linesPrepended++
	}

	for varName := range task.Params {
		// Include $(date) so shellcheck does not assume contents are safe
		script += fmt.Sprintf("%s=DUMMY-$(date)\n", varName)
		script += fmt.Sprintf("export %s\n", varName)
		linesPrepended += 2
	}

	for varName := range params {
		// Include $(date) so shellcheck does not assume contents are safe
		script += fmt.Sprintf("%s=DUMMY-$(date)\n", varName)
		script += fmt.Sprintf("export %s\n", varName)
		linesPrepended += 2
	}

	script += concourseVarRegexp.ReplaceAllLiteralString(
		task.Run.Args[len(task.Run.Args)-1],
		"DUMMY-$(date)", // Replace any ((concourse-var)) with unsafe shell code
	)

	cmd := exec.Command(
		"shellcheck",

		"--shell", dialect,

		"--format", "json",
		"--severity", "style",

		"--exclude", strings.Join([]string{
			"SC1091", // Do not follow . or source
		}, ","),

		"-",
	)
	var outStream bytes.Buffer
	var errStream bytes.Buffer

	cmd.Stdin = strings.NewReader(script)
	cmd.Stdout = &outStream
	cmd.Stderr = &errStream

	err := cmd.Run()

	if err == nil {
		// Everything worked, and shellcheck exited 0
		return errors
	}

	if cmd.ProcessState == nil {
		errors = append(errors, err)
		return errors
	}

	var shellcheckResults []shellcheckResult
	err = json.Unmarshal(outStream.Bytes(), &shellcheckResults)

	if err != nil {
		errors = append(errors, fmt.Errorf(
			"could not parse shellcheck results: %s; %s; %s",
			err, string(outStream.Bytes()), string(errStream.Bytes()),
		))
		return errors
	}

	for _, result := range shellcheckResults {
		// adjust for things we prepended to make shellcheck work
		realLineNumber := result.Line - linesPrepended

		errors = append(errors, fmt.Errorf(
			"SC%d on line %d on column %d: %s",
			result.Code, realLineNumber, result.Column, result.Message,
		))
	}

	return errors
}
