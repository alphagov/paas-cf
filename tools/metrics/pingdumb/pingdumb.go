package pingdumb

import (
	"context"
	"crypto/tls"
	"errors"
	"fmt"
	"net"
	"net/http"
	"net/url"
	"strings"
	"sync"
	"time"
)

type ReportConfig struct {
	Resolvers []*net.Resolver
	Timeout   time.Duration
	Target    string
}

func (config ReportConfig) resolvers() []*net.Resolver {
	if config.Resolvers != nil {
		return config.Resolvers
	}
	return []*net.Resolver{
		net.DefaultResolver,
		&net.Resolver{
			Dial: func(ctx context.Context, network, address string) (net.Conn, error) {
				dialer := &net.Dialer{
					Timeout:   config.Timeout,
					KeepAlive: config.Timeout,
					DualStack: true,
				}
				return dialer.DialContext(ctx, network, "8.8.8.8:53")
			},
		},
		&net.Resolver{
			Dial: func(ctx context.Context, network, address string) (net.Conn, error) {
				dialer := &net.Dialer{
					Timeout:   config.Timeout,
					KeepAlive: config.Timeout,
					DualStack: true,
				}
				return dialer.DialContext(ctx, network, "8.8.4.4:53")
			},
		},
	}
}

type Check struct {
	Start    time.Time
	Stop     time.Time
	Addr     string
	Response *http.Response
	err      error
}

func (c *Check) Err() error {
	if c.err != nil {
		return c.err
	}
	if c.Response == nil {
		return errors.New("no response object returned")
	}
	return nil
}

type Report struct {
	Start  time.Time
	Stop   time.Time
	Checks []*Check
	Target string
}

func (r *Report) Failures() []*Check {
	failures := []*Check{}
	for _, check := range r.Checks {
		if check.Err() != nil {
			failures = append(failures, check)
		}
	}
	return failures
}

func (r *Report) OK() bool {
	failures := r.Failures()
	return len(failures) == 0
}

// doRequest makes an HTTP GET request to target but dials the IP specified by addr
func doRequest(config ReportConfig, addr string) (*http.Response, error) {
	dialer := &net.Dialer{
		Timeout:   config.Timeout,
		KeepAlive: config.Timeout,
		DualStack: true,
	}
	client := http.Client{
		Transport: &http.Transport{
			DialContext: func(ctx context.Context, network, _ string) (net.Conn, error) {
				return dialer.DialContext(ctx, network, addr)
			},
			TLSClientConfig:       &tls.Config{InsecureSkipVerify: true},
			DisableKeepAlives:     true,
			IdleConnTimeout:       config.Timeout,
			TLSHandshakeTimeout:   config.Timeout,
			ExpectContinueTimeout: 1 * time.Second,
		},
		CheckRedirect: func(req *http.Request, via []*http.Request) error {
			return http.ErrUseLastResponse
		},
	}
	req, err := http.NewRequest("HEAD", config.Target, nil)
	if err != nil {
		return nil, err
	}
	ctx, cancel := context.WithTimeout(context.Background(), config.Timeout)
	defer cancel()
	req = req.WithContext(ctx)
	return client.Do(req)
}

// lookupAddrs finds as many IP addresses as possible for the target url
// * Use multiple resolvers (google, local, whatever) to attempt to work around
//   "clever" responses as much as possible
// * de-duplicate any addrs
func lookupAddrs(target string, resolvers []*net.Resolver) ([]string, error) {
	uri, err := url.Parse(target)
	if err != nil {
		return nil, err
	}
	port := uri.Port()
	if port == "" {
		switch uri.Scheme {
		case "http":
			port = "80"
		case "https":
			port = "443"
		default:
			return nil, fmt.Errorf("bad target URL: %s", target)
		}
	}
	uniqueAddrs := map[string]bool{}
	for _, resolver := range resolvers {
		ips, err := resolver.LookupIPAddr(context.TODO(), uri.Hostname())
		if err != nil {
			return nil, err
		}
		for _, ip := range ips {
			addr := ip.String()
			if addr == "<nil>" {
				continue
			}
			if strings.Contains(addr, ":") {
				addr = "[" + addr + "]"
			}
			if err != nil {
				return nil, err
			}
			addr = fmt.Sprintf("%s:%s", addr, port)
			uniqueAddrs[addr] = true
		}
	}
	addrs := []string{}
	for addr, _ := range uniqueAddrs {
		addrs = append(addrs, addr)
	}
	return addrs, nil
}

// getReport makes multiple HTTP GET requests to a target url (one request
// per IP addr found from DNS lookup)
func GetReport(config ReportConfig) (*Report, error) {
	addrs, err := lookupAddrs(config.Target, config.resolvers())
	if err != nil {
		return nil, err
	}
	var wg sync.WaitGroup
	r := &Report{
		Start:  time.Now(),
		Target: config.Target,
	}
	for _, addr := range addrs {
		check := &Check{
			Addr: addr,
		}
		wg.Add(1)
		go func(check *Check) {
			defer wg.Done()
			check.Start = time.Now()
			check.Response, check.err = doRequest(config, check.Addr)
			check.Stop = time.Now()
		}(check)
		r.Checks = append(r.Checks, check)
	}
	wg.Wait()
	r.Stop = time.Now()
	return r, nil
}
