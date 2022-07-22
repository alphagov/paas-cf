package monitor

import (
	"fmt"
	"time"
)

type Review struct {
	SuccessCount int64
	FailureCount int64
	WarningCount int64
	Errors       map[*Task]map[string]int // number of errors by error message by task
	Warnings     map[*Task]map[string]int // number of warnings by error message by task
	Elapsed      time.Duration
}

func (r *Review) badExecutions() int64 {
	return r.FailureCount + r.WarningCount
}

func (r *Review) TotalExecutions() int64 {
	return r.SuccessCount + r.badExecutions()
}

func (r *Review) PercentageGoodExecutions() float64 {
	return 100.0 * (float64(r.SuccessCount) / float64(r.TotalExecutions()))
}

func (r *Review) tasksPerSecond() float64 {
	return float64(r.TotalExecutions()) / r.Elapsed.Seconds()
}

func (r *Review) String() string {
	s := "\nReport:\n"
	s += "==============\n"
	s += fmt.Sprintf("Total task executions: %d\n", r.TotalExecutions())
	s += fmt.Sprintf("Good executions %%:     %5f%%\n", r.PercentageGoodExecutions())
	s += "--------------\n"
	s += fmt.Sprintf("Total successes:       %d\n", r.SuccessCount)
	s += fmt.Sprintf("Total bad executions:  %d\n", r.badExecutions())
	s += fmt.Sprintf("  -> failures:         %d\n", r.FailureCount)
	s += fmt.Sprintf("  -> warnings:         %d\n", r.WarningCount)
	s += "--------------\n"
	s += fmt.Sprintf("Elapsed time:          %s\n", r.Elapsed.String())
	s += fmt.Sprintf("Average rate:          %.2f tasks/sec\n", r.tasksPerSecond())

	if len(r.Errors) > 0 {
		s += fmt.Sprintf("\nErrors:\n")
		for task, errCounts := range r.Errors {
			s += fmt.Sprintf("\n    %s:\n", task.name)
			for err, count := range errCounts {
				s += fmt.Sprintf("        %s (%d failures)\n", err, count)
			}
		}
	}
	if len(r.Warnings) > 0 {
		s += fmt.Sprintf("\nWarnings:\n")
		for task, warningCounts := range r.Warnings {
			s += fmt.Sprintf("\n    %s:\n", task.name)
			for warning, count := range warningCounts {
				s += fmt.Sprintf("        %s (%d warnings)\n", warning, count)
			}
		}
	}
	return s
}
