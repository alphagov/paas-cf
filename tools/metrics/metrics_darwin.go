// +build darwin

package main

import "os"

func init() {
	os.Setenv("GODEBUG", "netdns=go")
}
