package monitor

import (
	"errors"
	"regexp"
	"time"

	cfclient "github.com/cloudfoundry-community/go-cfclient"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("Monitor", func() {
	var taskRatePerSecond int64

	BeforeEach(func() {
		taskRatePerSecond = 20
	})

	Context("When a task is registered", func() {
		It("should handle successful runs", func() {
			monitor := NewMonitor(&cfclient.Config{}, GinkgoWriter, 2, []*regexp.Regexp{}, taskRatePerSecond)
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

		It("should handle errors", func() {
			monitor := NewMonitor(&cfclient.Config{}, GinkgoWriter, 2, []*regexp.Regexp{}, taskRatePerSecond)
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
			}, taskRatePerSecond)
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

	Describe("rate limiting", func() {
		It("should limit the rate by which tasks are added to the queue", func() {
			monitor := NewMonitor(&cfclient.Config{}, GinkgoWriter, 2, []*regexp.Regexp{}, taskRatePerSecond)
			monitor.Add("consume as fast as possible", func(cfg *cfclient.Config) error {
				return nil
			})
			time.AfterFunc(3*time.Second, func() {
				monitor.Stop()
			})
			report := monitor.Run()

			expectedTaskLimit := taskRatePerSecond * 3

			Expect(report.SuccessCount).To(BeNumerically("<", expectedTaskLimit))
		})
	})
})
