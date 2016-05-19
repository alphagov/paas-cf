package run_from_vm_test

import (
	"bytes"
	"errors"
	"fmt"
	"net"
	"net/http"
	"net/url"
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
		JumboMTU       = 9000
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

	It("is running from a host configured to use jumbo frames", func() {
		egressAddr, err := EgressAddr(EndpointURL, DefaultTimeout)
		Expect(err).To(BeNil())

		egressIP, _, err := net.SplitHostPort(egressAddr.String())
		Expect(err).To(BeNil())

		iface, err := InterfaceByAddr(egressIP)
		Expect(err).To(BeNil())

		Expect(iface.MTU).To(BeNumerically("~", JumboMTU, 10))
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

// EgressAddr returns the address (host:port) of the network interface used
// to connect to `endpointURL`.
func EgressAddr(endpointURL string, timeout time.Duration) (net.Addr, error) {
	var (
		egressAddr   net.Addr
		errConnAbort error = errors.New("connection aborted because we only wanted the local addr")
	)

	dialHijack := func(network, addr string) (net.Conn, error) {
		conn, err := net.DialTimeout(network, addr, timeout)
		if err != nil {
			return conn, err
		}

		defer conn.Close()
		egressAddr = conn.LocalAddr()

		return nil, errConnAbort
	}

	client := &http.Client{
		Timeout: timeout,
		Transport: &http.Transport{
			Dial:    dialHijack,
			DialTLS: dialHijack,
		},
	}

	req, err := http.NewRequest("GET", endpointURL, nil)
	if err != nil {
		return nil, err
	}

	_, err = client.Do(req)
	if err != nil {
		if urlErr, ok := err.(*url.Error); !(ok && urlErr.Err == errConnAbort) {
			return nil, err
		}
	}

	return egressAddr, nil
}

// InterfaceByAddr returns the network interface that has the IP address
// `ipAddr`
func InterfaceByAddr(ipAddr string) (net.Interface, error) {
	ifaces, err := net.Interfaces()
	if err != nil {
		return net.Interface{}, err
	}

	for _, iface := range ifaces {
		addrs, err := iface.Addrs()
		if err != nil {
			continue
		}

		for _, addr := range addrs {
			ip, _, err := net.ParseCIDR(addr.String())
			if err == nil && ip.String() == ipAddr {
				return iface, nil
			}
		}
	}

	return net.Interface{}, fmt.Errorf("unable to find interface for IP %s", ipAddr)
}
