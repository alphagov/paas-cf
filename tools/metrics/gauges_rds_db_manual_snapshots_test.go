package main_test

import (
	"fmt"
	"time"

	"code.cloudfoundry.org/lager"
	. "github.com/alphagov/paas-cf/tools/metrics"
	"github.com/alphagov/paas-cf/tools/metrics/pkg/rds"
	"github.com/alphagov/paas-cf/tools/metrics/pkg/servicequotas"
	"github.com/aws/aws-sdk-go/aws"
	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"

	m "github.com/alphagov/paas-cf/tools/metrics/pkg/metrics"
	rdsfakes "github.com/alphagov/paas-cf/tools/metrics/pkg/rds/fakes"
	servicequotasfakes "github.com/alphagov/paas-cf/tools/metrics/pkg/servicequotas/fakes"
	awsrds "github.com/aws/aws-sdk-go/service/rds"
	awsservicequotas "github.com/aws/aws-sdk-go/service/servicequotas"
)

var _ = Describe("RDS DB Manual Snapshot Gauge", func() {
	var (
		rdsSvc           *rds.RDSService
		rdsAPI           *rdsfakes.FakeRDSAPI
		servicequotasSvc *servicequotas.ServiceQuotas
		servicequotasAPI *servicequotasfakes.FakeServiceQuotasAPI
		logger           lager.Logger

		rdsDatabaseSnapshots    []*awsrds.DBSnapshot
		describeDBSnapshotsStub = func(
			input *awsrds.DescribeDBSnapshotsInput,
		) (*awsrds.DescribeDBSnapshotsOutput, error) {
			return &awsrds.DescribeDBSnapshotsOutput{
				DBSnapshots: rdsDatabaseSnapshots,
			}, nil
		}

		quota               *float64
		getServiceQuotaStub = func(
			input *awsservicequotas.GetServiceQuotaInput,
		) (*awsservicequotas.GetServiceQuotaOutput, error) {
			return &awsservicequotas.GetServiceQuotaOutput{
				Quota: &awsservicequotas.ServiceQuota{Value: quota},
			}, nil
		}
	)

	BeforeEach(func() {
		rdsAPI = &rdsfakes.FakeRDSAPI{}
		rdsSvc = &rds.RDSService{Client: rdsAPI}
		servicequotasAPI = &servicequotasfakes.FakeServiceQuotasAPI{}
		servicequotasSvc = &servicequotas.ServiceQuotas{Client: servicequotasAPI}

		rdsAPI.DescribeDBSnapshotsStub = describeDBSnapshotsStub
		servicequotasAPI.GetServiceQuotaStub = getServiceQuotaStub

		logger = lager.NewLogger("rds-db-manual-snapshots-gauge-test")
		logger.RegisterSink(lager.NewWriterSink(GinkgoWriter, lager.DEBUG))
	})

	It("exposes a metric which counts the number of db manual snapshots", func() {
		rdsDatabaseSnapshots = []*awsrds.DBSnapshot{
			{DBSnapshotIdentifier: aws.String("snapshot1")},
			{DBSnapshotIdentifier: aws.String("snapshot2")},
		}
		quota = aws.Float64(float64(40))

		gauge := RDSDBManualSnapshotsGauge(logger, rdsSvc, servicequotasSvc, 1*time.Second)

		var metric m.Metric
		Eventually(func() string {
			var err error
			metric, err = gauge.ReadMetric()
			Expect(err).NotTo(HaveOccurred())
			return metric.Name
		}, 3*time.Second).Should(Equal("aws.rds.manual.snapshot.count"))

		Expect(metric.Value).To(Equal(float64(2)))

	})

	It("exposes the current RDS DB manual snapshot quota as a metric", func() {
		rdsDatabaseSnapshots = []*awsrds.DBSnapshot{
			{DBSnapshotIdentifier: aws.String("snapshot1")},
		}
		quota = aws.Float64(float64(40))

		gauge := RDSDBManualSnapshotsGauge(logger, rdsSvc, servicequotasSvc, 1*time.Second)

		var metric m.Metric
		Eventually(func() string {
			var err error
			metric, err = gauge.ReadMetric()
			Expect(err).NotTo(HaveOccurred())
			return metric.Name
		}, 3*time.Second).Should(Equal("aws.rds.manual.snapshot.quota.count"))

		Expect(metric.Value).To(Equal(float64(40)))

	})

	It("returns an error if describing RDS DB manual snapshot fails", func() {
		rdsAPI.DescribeDBSnapshotsStub = func(
			_ *awsrds.DescribeDBSnapshotsInput,
		) (*awsrds.DescribeDBSnapshotsOutput, error) {
			return nil, fmt.Errorf("error on purpose")
		}
		quota = aws.Float64(float64(40))

		gauge := RDSDBManualSnapshotsGauge(logger, rdsSvc, servicequotasSvc, 1*time.Second)
		Eventually(func() error {
			_, err := gauge.ReadMetric()
			return err
		}, 3*time.Second).ShouldNot(BeNil())
	})

	It("returns an error if getting the RDS manual snapshot quota fails", func() {
		rdsDatabaseSnapshots = []*awsrds.DBSnapshot{
			{DBSnapshotIdentifier: aws.String("snapshot1")},
		}

		servicequotasAPI.GetServiceQuotaStub = func(
			input *awsservicequotas.GetServiceQuotaInput,
		) (*awsservicequotas.GetServiceQuotaOutput, error) {
			return &awsservicequotas.GetServiceQuotaOutput{
				Quota: &awsservicequotas.ServiceQuota{Value: aws.Float64(float64(0))},
			}, fmt.Errorf("error on purpose")
		}

		gauge := RDSDBManualSnapshotsGauge(logger, rdsSvc, servicequotasSvc, 1*time.Second)
		Eventually(func() error {
			_, err := gauge.ReadMetric()
			return err
		}, 3*time.Second).ShouldNot(BeNil())
	})
})
