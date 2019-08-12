package pingdumb_test

import (
	"context"
	"fmt"
	"net"
	"net/http"
	"time"

	"github.com/alphagov/paas-cf/tools/metrics/fakes"
	. "github.com/alphagov/paas-cf/tools/metrics/pkg/pingdumb"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("Pingdumb", func() {
	var resolvers []*net.Resolver
	var server *http.Server

	BeforeSuite(func() {
		resolvers = []*net.Resolver{
			&net.Resolver{
				Dial: func(ctx context.Context, network, address string) (net.Conn, error) {
					dialer := &net.Dialer{}
					return dialer.DialContext(ctx, network, "127.0.0.1:8053")
				},
			},
		}

		records := map[string][]string{
			"local.test.": []string{
				"127.0.0.1",
				"0.0.0.0",
			},
		}

		go func() {
			defer GinkgoRecover()
			Expect(fakes.ListenAndServeDNS(":8053", records)).To(Succeed())
		}()

		server = fakes.ListenAndServeHTTP(":8080")
	})

	AfterSuite(func() {
		fakes.ShutdownDNS()
		server.Close()
	})

	It("produces a report", func() {
		config := ReportConfig{
			Target:    "http://local.test:8080/",
			Resolvers: resolvers,
			Timeout:   1 * time.Second,
		}
		var (
			r   *Report
			err error
		)
		Eventually(func() error {
			r, err = GetReport(config)
			return err
		}).Should(Succeed())
		Expect(len(r.Checks)).To(BeNumerically(">", 1))

		By("not translating HTTP error codes into failures")
		for _, check := range r.Checks {
			Expect(check.Err()).NotTo(HaveOccurred())
		}
		Expect(len(r.Failures())).To(Equal(0))
		Expect(r.OK()).To(BeTrue())

		By("including status codes")
		for _, check := range r.Checks {
			Expect(check.Response).NotTo(BeNil())
			Expect(check.Response.StatusCode).To(Equal(418))
		}

		By("checking multiple IPs")
		uniqueIPs := map[string]bool{}
		for _, check := range r.Checks {
			uniqueIPs[check.Addr] = true
		}
		Expect(len(uniqueIPs)).To(Equal(len(r.Checks)),
			fmt.Sprintf("Only got %d of %d expected unique IPs", len(uniqueIPs), len(r.Checks)))

		By("including request timestamps")
		for _, check := range r.Checks {
			Expect(check.Start).To(BeTemporally("~", time.Now(), 1*time.Hour))
			Expect(check.Stop).To(BeTemporally("~", time.Now(), 1*time.Hour))
			Expect(check.Stop).To(BeTemporally(">", check.Start))
		}
	})

	It("produces an error when it can't resolve the target", func() {
		config := ReportConfig{
			Target:  "https://this.domain.is.invalid/",
			Timeout: 1 * time.Second,
		}
		_, err := GetReport(config)
		_, ok := err.(*net.DNSError)
		Expect(ok).To(BeTrue(), "expected net.DNSError")
	})

	It("returns failures on hanging connections", func() {
		config := ReportConfig{
			Target:    "http://local.test:8080/?hang=true",
			Timeout:   100 * time.Millisecond,
			Resolvers: resolvers,
		}
		r, err := GetReport(config)
		Expect(err).ToNot(HaveOccurred())
		Expect(len(r.Failures())).To(Equal(2))
		Expect(r.OK()).To(BeFalse())
		for _, check := range r.Checks {
			Expect(check.Err()).To(HaveOccurred())
			Expect(check.Err().Error()).To(ContainSubstring("context deadline exceeded"))
		}
	})
})
