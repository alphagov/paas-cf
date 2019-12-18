package main

import (
	"fmt"
	"io/ioutil"

	"github.com/concourse/concourse/atc"
	"sigs.k8s.io/yaml"
)

type eitherPipelineOrTaskError struct {
	PipelineError error
	TaskError     error
}

func (e eitherPipelineOrTaskError) Error() string {
	return fmt.Sprintf(`PARSE error: could not parse as either pipeline or task
	Pipeline:
%s
	Task
%s
`, indent(indent(e.PipelineError)), indent(indent(e.TaskError)))
}

func ParsePipelineOrTask(filename string) (*atc.Config, *atc.TaskConfig, error) {
	var pipelineParseErr error
	var pipelineConfig atc.Config

	var taskParseErr error
	var taskConfig atc.TaskConfig

	contents, err := ioutil.ReadFile(filename)

	if err != nil {
		return nil, nil, fmt.Errorf("PARSE error: %s", err)
	}

	// It is a common pattern to have a variable for trigger
	// we should set this to a boolean, so that we can parse as YAML
	contents = resourceTriggerRegexp.ReplaceAllLiteral(
		contents,
		[]byte("trigger: true"),
	)

	pipelineParseErr = yaml.Unmarshal(contents, &pipelineConfig)
	if pipelineParseErr == nil && len(pipelineConfig.Jobs) > 0 {
		return &pipelineConfig, nil, nil
	}

	taskParseErr = yaml.Unmarshal(contents, &taskConfig)
	if taskParseErr == nil && taskConfig.Platform != "" {
		return nil, &taskConfig, nil
	}

	if pipelineParseErr == nil && len(pipelineConfig.Jobs) == 0 {
		pipelineParseErr = fmt.Errorf("Did not parse any jobs in pipeline")
	}
	if taskParseErr == nil && taskConfig.Platform == "" {
		taskParseErr = fmt.Errorf("Did not parse platform in task")
	}
	return nil, nil, eitherPipelineOrTaskError{
		PipelineError: pipelineParseErr,
		TaskError:     taskParseErr,
	}
}
