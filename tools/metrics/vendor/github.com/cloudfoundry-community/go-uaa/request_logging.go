package uaa

import (
	"fmt"
	"net/http"
	"net/http/httputil"

	"github.com/fatih/color"
)

func is2XX(status int) bool {
	if status >= 200 && status < 300 {
		return true
	}
	return false
}

func logResponse(response *http.Response) {
	dumped, _ := httputil.DumpResponse(response, true)

	if is2XX(response.StatusCode) {
		fmt.Println(color.New(color.FgGreen).SprintFunc()(string(dumped)) + "\n")
	} else {
		fmt.Println(color.New(color.FgRed).SprintFunc()(string(dumped)) + "\n")
	}
}

func logRequest(request *http.Request) {
	dumped, _ := httputil.DumpRequest(request, true)
	fmt.Println(string(dumped))
}
