package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/concourse/concourse/atc"
)

var (
	rubocopValidator = taskValidator{
		Name:       "rubocop",
		ValidateFn: rubocopTask,
	}
)

type rubocopLocation struct {
	Line   int `json:"line"`
	Column int `json:"column"`
}

type rubocopOffense struct {
	CopName  string          `json:"cop_name"`
	Location rubocopLocation `json:"location"`
	Message  string          `json:"message"`
}

type rubocopReport struct {
	Offenses []rubocopOffense `json:"offenses"`
}

type rubocopResult struct {
	Files []rubocopReport `json:"files"`
}

func rubocopTask(task atc.TaskConfig, params atc.TaskEnv) []error {
	errors := make([]error, 0)

	if task.Run.Path != "ruby" {
		return errors
	}

	script := concourseVarRegexp.ReplaceAllLiteralString(
		task.Run.Args[len(task.Run.Args)-1],
		"DUMMY", // Replace any ((concourse-var)) with a real value
	)

	// Rubocop doing things from STDIN is unreliable
	// Use a temporary file instead
	dir, err := ioutil.TempDir("", "rubocop")
	if err != nil {
		return append(errors, err)
	}
	defer os.RemoveAll(dir)
	path := filepath.Join(dir, "rubocop.rb")
	if err := ioutil.WriteFile(path, []byte(script), 0666); err != nil {
		return append(errors, err)
	}

	cmd := exec.Command("rubocop", "--format", "json", path)
	var outStream bytes.Buffer
	var errStream bytes.Buffer

	cmd.Stdin = strings.NewReader(script)
	cmd.Stdout = &outStream
	cmd.Stderr = &errStream

	err = cmd.Run()

	if err == nil {
		// Everything worked, and rubocop exited 0
		return errors
	}

	if cmd.ProcessState == nil {
		errors = append(errors, err)
		return errors
	}

	var result rubocopResult
	err = json.Unmarshal(outStream.Bytes(), &result)

	if err != nil {
		errors = append(errors, fmt.Errorf(
			"could not parse rubocop results: %s; %s; %s",
			err, string(outStream.Bytes()), string(errStream.Bytes()),
		))
		return errors
	}

	if len(result.Files) != 1 {
		return append(
			errors,
			fmt.Errorf(
				"Expected 1 result from rubocop, not %d", len(result.Files),
			),
		)
	}

	for _, offense := range result.Files[0].Offenses {
		// adjust for things we prepended to make shellcheck work
		errors = append(errors, fmt.Errorf(
			"%s on line %d on column %d: %s",
			offense.CopName,
			offense.Location.Line, offense.Location.Column,
			offense.Message,
		))
	}

	return errors
}
