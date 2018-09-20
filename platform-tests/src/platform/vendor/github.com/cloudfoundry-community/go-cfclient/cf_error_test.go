package cfclient

import (
	stderrors "errors"
	"testing"

	pkgerrors "github.com/pkg/errors"
)

func TestIsSpaceNotFoundError(t *testing.T) {
	tests := []struct {
		name string
		error
		want bool
	}{
		{"std/errors error", stderrors.New("is not"), false},
		{"pkg/errors error", pkgerrors.New("is not"), false},
		{"unwrapped CloudFoundry error", CloudFoundryError{
			Code: 40004,
		}, true},
		{"wrapped CloudFoundry error", pkgerrors.Wrap(CloudFoundryError{
			Code: 40004,
		}, ""), true},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := IsSpaceNotFoundError(tt.error)
			if got != tt.want {
				t.Errorf("got %v, want %v", got, tt.want)
			}
		})
	}
}
