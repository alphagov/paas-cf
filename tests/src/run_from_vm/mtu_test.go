package run_from_vm_test

import (
	"bytes"
	"fmt"
	"net/http"
	"os"
	"strings"
	"time"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("MTU", func() {
	const (
		DefaultTimeout = time.Second
		HeaderName     = "Authorization"
		HeaderBase     = "bearer ="
		ReqSizeMin     = 1300
		ReqSizeMax     = 1500
	)

	var (
		EndpointURL string
	)

	BeforeEach(func() {
		EndpointURL = os.Getenv("API_ENDPOINT")
		Expect(EndpointURL).ToNot(BeEmpty(), "API_ENDPOINT environment variable must be set")
	})

	It("can access the endpoint with a variety of request sizes", func() {
		req, err := http.NewRequest("GET", EndpointURL, nil)
		Expect(err).To(BeNil())

		var buf bytes.Buffer
		req.Header.Set(HeaderName, HeaderBase)
		req.Write(&buf)
		baseSize := buf.Len()

		client := &http.Client{Timeout: DefaultTimeout}
		var padding string
		for reqSize := ReqSizeMin; reqSize <= ReqSizeMax; reqSize++ {
			By(fmt.Sprintf("using request size of %d bytes", reqSize))
			padding = strings.Repeat("=", reqSize-baseSize)
			req.Header.Set(HeaderName, HeaderBase+padding)

			buf.Reset()
			req.Write(&buf)
			Expect(buf.Len()).To(Equal(reqSize))

			_, err := client.Do(req)
			Expect(err).To(BeNil(), "request failed with size of %d bytes", reqSize)
		}
	})
})
