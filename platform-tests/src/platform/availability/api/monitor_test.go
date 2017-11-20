package api_availability_test

import (
	"errors"
	. "platform/availability/api"
	"regexp"
	"time"

	cfclient "github.com/cloudfoundry-community/go-cfclient"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("Monitor", func() {
	Context("When a task is registered", func() {

		It("should collect successful runs", func() {
			monitor := NewMonitor(&cfclient.Config{}, GinkgoWriter, 2, []*regexp.Regexp{})
			monitor.Add("test", func(cfg *cfclient.Config) error {
				<-time.After(1 * time.Second)
				return nil
			})
			time.AfterFunc(3*time.Second, func() {
				monitor.Stop()
			})
			report := monitor.Run()

			Expect(report.SuccessCount).To(BeNumerically(">", 0))
			Expect(report.FailureCount).To(Equal(int64(0)))
			Expect(report.WarningCount).To(Equal(int64(0)))
		}, 4)

		It("should collect errors", func() {
			monitor := NewMonitor(&cfclient.Config{}, GinkgoWriter, 2, []*regexp.Regexp{})
			monitor.Add("test", func(cfg *cfclient.Config) error {
				<-time.After(1 * time.Second)
				return errors.New("some error")
			})
			time.AfterFunc(3*time.Second, func() {
				monitor.Stop()
			})
			report := monitor.Run()

			Expect(report.SuccessCount).To(Equal(int64(0)))
			Expect(report.FailureCount).To(BeNumerically(">", 0))
			Expect(report.WarningCount).To(Equal(int64(0)))
		}, 4)

		It("should handle specific errors as warning", func() {
			monitor := NewMonitor(&cfclient.Config{}, GinkgoWriter, 2, []*regexp.Regexp{
				regexp.MustCompile("this is a warning"),
			})
			monitor.Add("test", func(cfg *cfclient.Config) error {
				<-time.After(1 * time.Second)
				return errors.New("foo, this is a warning, bar")
			})
			time.AfterFunc(3*time.Second, func() {
				monitor.Stop()
			})
			report := monitor.Run()

			Expect(report.SuccessCount).To(Equal(int64(0)))
			Expect(report.FailureCount).To(Equal(int64(0)))
			Expect(report.WarningCount).To(BeNumerically(">", 0))
		}, 4)

	})
})
