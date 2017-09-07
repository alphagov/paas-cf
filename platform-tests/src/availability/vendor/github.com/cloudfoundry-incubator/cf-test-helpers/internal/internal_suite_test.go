package internal_test

import (
	"bytes"
	"fmt"
	"os/exec"
	"time"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"

	"testing"
)

type fakeReporter struct {
	calledWith struct {
		startTime time.Time
		cmd       *exec.Cmd
	}
	outputBuffer *bytes.Buffer
}

func (r *fakeReporter) Report(startTime time.Time, cmd *exec.Cmd) {
	r.calledWith.startTime = startTime
	r.calledWith.cmd = cmd

	fmt.Fprintf(r.outputBuffer, "Reporter reporting for duty")
}

func TestInternal(t *testing.T) {
	RegisterFailHandler(Fail)
	RunSpecs(t, "CF Internal Suite")
}
