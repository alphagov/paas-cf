package utils

import (
	"fmt"
	"github.com/briandowns/spinner"
	"github.com/fatih/color"
	"io"
	"os"
	"time"
)

// This file was taken as a copy from
// https://github.com/alphagov/paas-cf-conduit/blob/a20379de044ee452ef054c08af08e1567008b402/util/status.go
// We wanted the same functionality as it supplies,
// but we didn't think importing the whole cf-conduit
// package was the right approach.
type Status struct {
	spin           *spinner.Spinner
	nonInteractive bool
}

func NewStatus(w io.Writer, nonInteractive bool) *Status {
	s := &Status{
		spin:           spinner.New(spinner.CharSets[14], 250*time.Millisecond),
		nonInteractive: nonInteractive,
	}
	s.spin.Writer = os.Stderr
	s.spin.Prefix = ""
	s.spin.Suffix = ""
	return s
}

func (s *Status) Text(args ...interface{}) {
	if s.spin.Suffix != "" {
		s.Done()
	}
	msg := fmt.Sprintln(args...)
	msg = msg[:len(msg)-1]

	s.spin.Suffix = " " + msg
	s.spin.Start()
}

func (s *Status) Done() {
	if s.spin.Suffix != "" {
		s.spin.FinalMSG = color.GreenString("OK") + s.spin.Suffix + "\n"
	}
	s.spin.Stop()
	s.spin.Suffix = ""

}
