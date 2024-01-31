package atc

import (
	"fmt"
	"path/filepath"
	"strings"

	"github.com/jessevdk/go-flags"
)

type PathFlag string

func (path *PathFlag) UnmarshalFlag(value string) error {
	if value == "" {
		return nil
	}

	matches, err := filepath.Glob(value)
	if err != nil {
		return fmt.Errorf("failed to expand path '%s': %s", value, err)
	}

	if len(matches) == 0 {
		return fmt.Errorf("path '%s' does not exist", value)
	}

	if len(matches) > 1 {
		return fmt.Errorf("path '%s' resolves to multiple entries: %s", value, strings.Join(matches, ", "))
	}

	*path = PathFlag(matches[0])
	return nil
}

func (path *PathFlag) Complete(match string) []flags.Completion {
	matches, _ := filepath.Glob(match + "*")
	comps := make([]flags.Completion, len(matches))

	for i, v := range matches {
		comps[i].Item = v
	}

	return comps
}
