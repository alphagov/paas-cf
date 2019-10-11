package main

import (
	"fmt"
	"strconv"
	"time"

	"code.cloudfoundry.org/lager"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/costexplorer"

	m "github.com/alphagov/paas-cf/tools/metrics/pkg/metrics"
)

func AWSCostExplorerGauge(
	logger lager.Logger,
	awsRegion string,
	costExplorer *costexplorer.CostExplorer,
	interval time.Duration,
) m.MetricReadCloser {
	return m.NewMetricPoller(interval, func(w m.MetricWriter) error {
		twoDaysAgo := time.Now().AddDate(0, 0, -2)
		year, month, date := twoDaysAgo.Date()

		metrics := []m.Metric{}

		serviceUsage, err := awsServiceUsageInRegionOnDate(awsRegion, year, month, date, costExplorer)
		if err != nil {
			return err
		}
		for _, group := range serviceUsage {
			serviceName := *group.Keys[0]

			amortizedCost, err := strconv.ParseFloat(*group.Metrics["AmortizedCost"].Amount, 64)
			if err != nil {
				logger.Fatal("5", fmt.Errorf("error parsing service amortized cost as float: %s", err))
			}

			metrics = append(metrics, m.Metric{
				Kind:  m.Gauge,
				Time:  twoDaysAgo,
				Name:  "aws.cost_explorer.by_service",
				Value: amortizedCost,
				Unit:  "dollars",
				Tags: m.MetricTags{
					{Label: "type", Value: "AmortizedCost"},
					{Label: "service", Value: serviceName},
				},
			})
		}

		regionUsage, err := awsRegionUsageOnDate(year, month, date, costExplorer)
		if err != nil {
			return err
		}
		for _, group := range regionUsage {
			regionName := *group.Keys[0]

			amortizedCost, err := strconv.ParseFloat(*group.Metrics["AmortizedCost"].Amount, 64)
			if err != nil {
				logger.Fatal("5", fmt.Errorf("error parsing region amortized cost as float: %s", err))
			}

			metrics = append(metrics, m.Metric{
				Kind:  m.Gauge,
				Time:  twoDaysAgo,
				Name:  "aws.cost_explorer.by_region",
				Value: amortizedCost,
				Unit:  "pounds",
				Tags: m.MetricTags{
					{Label: "type", Value: "AmortizedCost"},
					{Label: "region", Value: regionName},
				},
			})
		}

		return w.WriteMetrics(metrics)
	})
}

func awsServiceUsageInRegionOnDate(awsRegion string, year int, month time.Month, date int, costExplorer *costexplorer.CostExplorer) ([]*costexplorer.Group, error) {
	from := time.Date(year, month, date, 0, 0, 0, 0, time.Now().Location())
	to := from.AddDate(0, 0, 1)
	// This is the equivalent of:
	// aws-vault exec paas-dev -- aws ce get-cost-and-usage \
	//    --time-period Start=2019-07-29,End=2019-07-30 \
	//    --granularity DAILY \
	//    --filter '{"Dimensions": {"Key": "REGION", "Values": ["eu-west-2"]}}' \
	//    --metrics AmortizedCost \
	//    --group-by '[{"Type": "DIMENSION", "Key": "SERVICE"}]'
	query := costexplorer.GetCostAndUsageInput{
		Metrics:     []*string{aws.String(costexplorer.MetricAmortizedCost)},
		Granularity: aws.String(costexplorer.GranularityDaily),
		TimePeriod: &costexplorer.DateInterval{
			Start: aws.String(from.Format("2006-01-02")),
			End:   aws.String(to.Format("2006-01-02")),
		},
		Filter: &costexplorer.Expression{
			Dimensions: &costexplorer.DimensionValues{
				Key:    aws.String("REGION"),
				Values: []*string{aws.String(awsRegion)},
			},
		},
		GroupBy: []*costexplorer.GroupDefinition{&costexplorer.GroupDefinition{
			Type: aws.String("DIMENSION"),
			Key:  aws.String("SERVICE"),
		}},
	}
	if err := query.Validate(); err != nil {
		return nil, err
	}

	req, costAndUsageOutput := costExplorer.GetCostAndUsageRequest(&query)
	if err := req.Send(); err != nil {
		return nil, err
	}
	if len(costAndUsageOutput.ResultsByTime) != 1 {
		return nil, fmt.Errorf("unexpected number of results from costexplorer: expected 1, actual %d", len(costAndUsageOutput.ResultsByTime))
	}
	return costAndUsageOutput.ResultsByTime[0].Groups, nil
}

func awsRegionUsageOnDate(year int, month time.Month, date int, costExplorer *costexplorer.CostExplorer) ([]*costexplorer.Group, error) {
	from := time.Date(year, month, date, 0, 0, 0, 0, time.Now().Location())
	to := from.AddDate(0, 0, 1)
	// This is the equivalent of:
	// aws-vault exec paas-dev -- aws ce get-cost-and-usage \
	//   --time-period Start=2019-07-29,End=2019-07-30 \
	//   --granularity DAILY \
	//   --metrics AmortizedCost \
	//   --group-by '[{"Type": "DIMENSION", "Key": "REGION"}]'
	query := costexplorer.GetCostAndUsageInput{
		Metrics:     []*string{aws.String(costexplorer.MetricAmortizedCost)},
		Granularity: aws.String(costexplorer.GranularityDaily),
		TimePeriod: &costexplorer.DateInterval{
			Start: aws.String(from.Format("2006-01-02")),
			End:   aws.String(to.Format("2006-01-02")),
		},
		GroupBy: []*costexplorer.GroupDefinition{&costexplorer.GroupDefinition{
			Type: aws.String("DIMENSION"),
			Key:  aws.String("REGION"),
		}},
	}
	if err := query.Validate(); err != nil {
		return nil, err
	}

	req, costAndUsageOutput := costExplorer.GetCostAndUsageRequest(&query)
	if err := req.Send(); err != nil {
		return nil, err
	}
	if len(costAndUsageOutput.ResultsByTime) != 1 {
		return nil, fmt.Errorf("unexpected number of results from costexplorer: expected 1, actual %d", len(costAndUsageOutput.ResultsByTime))
	}
	return costAndUsageOutput.ResultsByTime[0].Groups, nil
}
