package monitor

import (
	"math"

	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
)

var _ = Describe("Review", func() {
	Context("Bad executions", func() {
		It("should calculate zero bad executions", func() {
			report := Review{FailureCount: 0, WarningCount: 0}
			Expect(report.badExecutions()).To(BeNumerically("==", 0))
		})

		It("should calculate bad executions only failures", func() {
			report := Review{FailureCount: 7, WarningCount: 0}
			Expect(report.badExecutions()).To(BeNumerically("==", 7))
		})

		It("should calculate bad executions only errors", func() {
			report := Review{FailureCount: 0, WarningCount: 9}
			Expect(report.badExecutions()).To(BeNumerically("==", 9))
		})

		It("should calculate bad executions", func() {
			report := Review{FailureCount: 7, WarningCount: 9}
			Expect(report.badExecutions()).To(BeNumerically("==", 16))
		})
	})

	Context("Total executions", func() {
		It("should calculate zero executions", func() {
			report := Review{SuccessCount: 0, FailureCount: 0, WarningCount: 0}
			Expect(report.TotalExecutions()).To(BeNumerically("==", 0))
		})

		It("should calculate only bad executions", func() {
			report := Review{SuccessCount: 0, FailureCount: 7, WarningCount: 9}
			Expect(report.TotalExecutions()).To(BeNumerically("==", 16))
		})

		It("should calculate only good executions", func() {
			report := Review{SuccessCount: 11, FailureCount: 0, WarningCount: 0}
			Expect(report.TotalExecutions()).To(BeNumerically("==", 11))
		})

		It("should calculate total executions", func() {
			report := Review{SuccessCount: 11, FailureCount: 7, WarningCount: 9}
			Expect(report.TotalExecutions()).To(BeNumerically("==", 27))
		})
	})

	Context("Percentage good executions", func() {
		It("should return NaN for zero executions", func() {
			report := Review{SuccessCount: 0, FailureCount: 0, WarningCount: 0}

			Expect(
				math.IsNaN(report.PercentageGoodExecutions()),
			).To(
				Equal(true),
			)
		})

		It("should calculate only bad executions", func() {
			report := Review{SuccessCount: 0, FailureCount: 7, WarningCount: 9}

			Expect(
				report.PercentageGoodExecutions(),
			).To(
				BeNumerically("==", 0.0),
			)
		})

		It("should calculate only good executions", func() {
			report := Review{SuccessCount: 11, FailureCount: 0, WarningCount: 0}

			Expect(
				report.PercentageGoodExecutions(),
			).To(
				BeNumerically("==", 100.0),
			)
		})

		It("should calculate total executions", func() {
			report := Review{SuccessCount: 11, FailureCount: 7, WarningCount: 9}

			Expect(
				report.PercentageGoodExecutions(),
			).To(
				BeNumerically("~", 40.75, 0.01),
			)
		})

		It("should calculate large total executions", func() {
			report := Review{SuccessCount: 13000, FailureCount: 3, WarningCount: 2}

			Expect(
				report.PercentageGoodExecutions(),
			).To(
				BeNumerically("~", 99.96, 0.01),
			)
		})
	})
})
