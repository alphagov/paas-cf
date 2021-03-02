package main_test

import (
	"code.cloudfoundry.org/lager"
	"fmt"
	. "github.com/alphagov/paas-cf/tools/metrics"
	"github.com/alphagov/paas-cf/tools/metrics/pkg/rds"
	"github.com/alphagov/paas-cf/tools/metrics/pkg/servicequotas"
	"github.com/aws/aws-sdk-go/aws"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	"time"

	m "github.com/alphagov/paas-cf/tools/metrics/pkg/metrics"
	rdsfakes "github.com/alphagov/paas-cf/tools/metrics/pkg/rds/fakes"
	servicequotasfakes "github.com/alphagov/paas-cf/tools/metrics/pkg/servicequotas/fakes"
	awsrds "github.com/aws/aws-sdk-go/service/rds"
	awsservicequotas "github.com/aws/aws-sdk-go/service/servicequotas"
)

var _ = Describe("RDS DB Instances Gauge", func() {
	var (
		rdsSvc           *rds.RDSService
		rdsAPI           *rdsfakes.FakeRDSAPI
		servicequotasSvc *servicequotas.ServiceQuotas
		servicequotasAPI *servicequotasfakes.FakeServiceQuotasAPI
		logger           lager.Logger

		rdsDatabaseInstances               []*awsrds.DBInstance
		describeDatabaseInstancesPagesStub = func(
			input *awsrds.DescribeDBInstancesInput,
			fn func(*awsrds.DescribeDBInstancesOutput, bool) bool,
		) error {
			for i, dbInstance := range rdsDatabaseInstances {
				page := &awsrds.DescribeDBInstancesOutput{
					DBInstances: []*awsrds.DBInstance{dbInstance},
				}
				if !fn(page, i+1 >= len(rdsDatabaseInstances)) {
					break
				}
			}
			return nil
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

		rdsAPI.DescribeDBInstancesPagesStub = describeDatabaseInstancesPagesStub
		servicequotasAPI.GetServiceQuotaStub = getServiceQuotaStub

		logger = lager.NewLogger("rds-db-instances-gauge-test")
		logger.RegisterSink(lager.NewWriterSink(GinkgoWriter, lager.DEBUG))
	})

	It("exposes a metric which counts the number of AWS RDS db instances", func() {
		rdsDatabaseInstances = []*awsrds.DBInstance{
			{DBInstanceIdentifier: aws.String("db1")},
			{DBInstanceIdentifier: aws.String("db2")},
		}
		quota = aws.Float64(float64(40))

		gauge := RDSDBInstancesGauge(logger, rdsSvc, servicequotasSvc, 1*time.Second)

		var metric m.Metric
		Eventually(func() string {
			var err error
			metric, err = gauge.ReadMetric()
			Expect(err).NotTo(HaveOccurred())
			return metric.Name
		}, 3*time.Second).Should(Equal("aws.rds.dbinstances.count"))

		Expect(metric.Value).To(Equal(float64(2)))

	})

	It("exposes the current RDS DB instance quota as a metric", func() {
		rdsDatabaseInstances = []*awsrds.DBInstance{
			{DBInstanceIdentifier: aws.String("db1")},
		}
		quota = aws.Float64(float64(40))

		gauge := RDSDBInstancesGauge(logger, rdsSvc, servicequotasSvc, 1*time.Second)

		var metric m.Metric
		Eventually(func() string {
			var err error
			metric, err = gauge.ReadMetric()
			Expect(err).NotTo(HaveOccurred())
			return metric.Name
		}, 3*time.Second).Should(Equal("aws.rds.dbinstances.quota.count"))

		Expect(metric.Value).To(Equal(float64(40)))

	})

	It("returns an error if describing RDS DB instances fails", func() {
		rdsAPI.DescribeDBInstancesPagesStub = func(
			_ *awsrds.DescribeDBInstancesInput,
			_ func(*awsrds.DescribeDBInstancesOutput, bool) bool,
		) error {
			return fmt.Errorf("error on purpose")
		}
		quota = aws.Float64(float64(40))

		gauge := RDSDBInstancesGauge(logger, rdsSvc, servicequotasSvc, 1*time.Second)
		Eventually(func() error {
			_, err := gauge.ReadMetric()
			return err
		}, 3*time.Second).ShouldNot(BeNil())
	})

	It("returns an error if getting the RDS DB instance quota fails", func() {
		rdsDatabaseInstances = []*awsrds.DBInstance{
			{DBInstanceIdentifier: aws.String("db1")},
		}
		servicequotasAPI.GetServiceQuotaStub = func(
			input *awsservicequotas.GetServiceQuotaInput,
		) (*awsservicequotas.GetServiceQuotaOutput, error) {
			return &awsservicequotas.GetServiceQuotaOutput{
				Quota: &awsservicequotas.ServiceQuota{Value: aws.Float64(float64(0))},
			}, fmt.Errorf("error on purpose")
		}

		gauge := RDSDBInstancesGauge(logger, rdsSvc, servicequotasSvc, 1*time.Second)
		Eventually(func() error {
			_, err := gauge.ReadMetric()
			return err
		}, 3*time.Second).ShouldNot(BeNil())
	})
})
