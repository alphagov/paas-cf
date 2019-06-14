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
	var (
		taskRatePerSecond int64
		targetReliability float64
	)

	BeforeEach(func() {
		taskRatePerSecond = 20
		targetReliability = 99.95
	})

	Context("When a task is registered", func() {
		It("should handle successful runs", func() {
			monitor := NewMonitor(
				&cfclient.Config{}, GinkgoWriter, 2, []*regexp.Regexp{},
				taskRatePerSecond, targetReliability,
			)
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
			monitor := NewMonitor(
				&cfclient.Config{}, GinkgoWriter, 2, []*regexp.Regexp{},
				taskRatePerSecond, targetReliability,
			)
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
			monitor := NewMonitor(
				&cfclient.Config{}, GinkgoWriter, 2,
				[]*regexp.Regexp{regexp.MustCompile("this is a warning")},
				taskRatePerSecond, targetReliability,
			)
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

	Context("Rate limiting", func() {
		It("should limit the rate by which tasks are added to the queue", func() {
			monitor := NewMonitor(
				&cfclient.Config{}, GinkgoWriter, 2, []*regexp.Regexp{},
				taskRatePerSecond, targetReliability,
			)
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

	Context("Acceptance or failure", func() {
		It("should fail if the targetReliability is not set", func() {
			monitor := NewMonitor(
				&cfclient.Config{}, GinkgoWriter, 2, []*regexp.Regexp{},
				taskRatePerSecond, 0.0,
			)

			Expect(monitor.HaveTestsPassed(Report{})).To(Equal(false))
		})

		It("should fail if the tests have not run", func() {
			monitor := NewMonitor(
				&cfclient.Config{}, GinkgoWriter, 2, []*regexp.Regexp{},
				taskRatePerSecond, targetReliability,
			)

			report := Report{
				SuccessCount: 0, WarningCount: 0, FailureCount: 0,
			}

			Expect(monitor.HaveTestsPassed(report)).To(Equal(false))
		})

		It("should fail if there are no successes", func() {
			monitor := NewMonitor(
				&cfclient.Config{}, GinkgoWriter, 2, []*regexp.Regexp{},
				taskRatePerSecond, targetReliability,
			)

			report := Report{
				SuccessCount: 0, WarningCount: 7, FailureCount: 9,
			}

			Expect(monitor.HaveTestsPassed(report)).To(Equal(false))
		})

		It("should pass if there are no failures", func() {
			monitor := NewMonitor(
				&cfclient.Config{}, GinkgoWriter, 2, []*regexp.Regexp{},
				taskRatePerSecond, targetReliability,
			)

			report := Report{
				SuccessCount: 1, WarningCount: 0, FailureCount: 0,
			}

			Expect(monitor.HaveTestsPassed(report)).To(Equal(true))
		})

		It("should pass if there are some warnings", func() {
			monitor := NewMonitor(
				&cfclient.Config{}, GinkgoWriter, 2, []*regexp.Regexp{},
				taskRatePerSecond, targetReliability,
			)

			report := Report{
				SuccessCount: 5000, WarningCount: 2, FailureCount: 0,
			}

			Expect(monitor.HaveTestsPassed(report)).To(Equal(true))
		})

		It("should pass if there are some failures", func() {
			monitor := NewMonitor(
				&cfclient.Config{}, GinkgoWriter, 2, []*regexp.Regexp{},
				taskRatePerSecond, targetReliability,
			)

			report := Report{
				SuccessCount: 5000, WarningCount: 0, FailureCount: 2,
			}

			Expect(monitor.HaveTestsPassed(report)).To(Equal(true))
		})

		It("should pass if there are bad executions", func() {
			monitor := NewMonitor(
				&cfclient.Config{}, GinkgoWriter, 2, []*regexp.Regexp{},
				taskRatePerSecond, targetReliability,
			)

			report := Report{
				SuccessCount: 5000, WarningCount: 1, FailureCount: 1,
			}

			Expect(monitor.HaveTestsPassed(report)).To(Equal(true))
		})
	})
})
