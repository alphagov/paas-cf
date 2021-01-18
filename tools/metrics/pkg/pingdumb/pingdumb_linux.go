// +build linux

package pingdumb

import "os"

func init() {
	os.Setenv("GODEBUG", "netdns=go")
}
