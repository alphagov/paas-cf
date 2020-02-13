package main_test

import (
	"fmt"
	. "github.com/alphagov/paas-cf/tools/metrics"
	"github.com/alphagov/paas-cf/tools/metrics/pkg/rds"
	"github.com/aws/aws-sdk-go/aws"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	"time"

	m "github.com/alphagov/paas-cf/tools/metrics/pkg/metrics"
	rdsfakes "github.com/alphagov/paas-cf/tools/metrics/pkg/rds/fakes"
	awsrds "github.com/aws/aws-sdk-go/service/rds"
)

var _ = Describe("RDS DB Instances Gauge", func() {
	var (
		rdsSvc *rds.RDSService
		rdsAPI *rdsfakes.FakeRDSAPI

		rdsDatabaseInstances []*awsrds.DBInstance
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
	)

	BeforeEach(func() {
		rdsAPI = &rdsfakes.FakeRDSAPI{}
		rdsSvc = &rds.RDSService{Client: rdsAPI}

		rdsAPI.DescribeDBInstancesPagesStub = describeDatabaseInstancesPagesStub
	})

	It("exposes a metric which counts the number of AWS RDS db instances", func() {
		rdsDatabaseInstances = []*awsrds.DBInstance{
			{ DBInstanceIdentifier: aws.String("db1")},
			{ DBInstanceIdentifier: aws.String("db2")},
		}

		gauge := RDSDBInstancesGauge(rdsSvc, 1*time.Second)

		var metric m.Metric
		Eventually(func() string {
			var err error
			metric, err = gauge.ReadMetric()
			Expect(err).NotTo(HaveOccurred())
			return metric.Name
		}, 3*time.Second).Should(Equal("aws.rds.dbinstances.count"))

		Expect(metric.Value).To(Equal(float64(2)))

	})

	It("returns an error if describing RDS DB instances fails", func(){
		rdsAPI.DescribeDBInstancesPagesStub = func(
			_ *awsrds.DescribeDBInstancesInput,
			_ func(*awsrds.DescribeDBInstancesOutput, bool) bool,
		) error {
			return fmt.Errorf("error on purpose")
		}

		gauge := RDSDBInstancesGauge(rdsSvc, 1*time.Second)
		Eventually(func() error {
			_, err := gauge.ReadMetric()
			return err
		}, 3*time.Second).ShouldNot(BeNil())
	})
})
