package main

import (
	"fmt"
	"os"
	"regexp"

	"golang.org/x/crypto/ssh/terminal"

	"github.com/logrusorgru/aurora"
)

var (
	indentRegexp          = regexp.MustCompile("(?m)^")
	concourseVarRegexp    = regexp.MustCompile(`\(\((!?[-/\.\w\pL]+)\)\)`)
	resourceTriggerRegexp = regexp.MustCompile(`trigger:\s+\(\((!?[-/\.\w\pL]+)\)\)`)
)

func indent(s interface{}) string {
	return indentRegexp.ReplaceAllLiteralString(fmt.Sprintf("%s", s), "\t")
}

func rColor(s string) string {
	if terminal.IsTerminal(int(os.Stdout.Fd())) {
		return fmt.Sprint(aurora.Red(s))
	}
	return s
}

func gColor(s string) string {
	if terminal.IsTerminal(int(os.Stdout.Fd())) {
		return fmt.Sprint(aurora.Green(s))
	}
	return s
}

func yColor(s string) string {
	if terminal.IsTerminal(int(os.Stdout.Fd())) {
		return fmt.Sprint(aurora.Yellow(s))
	}
	return s
}
