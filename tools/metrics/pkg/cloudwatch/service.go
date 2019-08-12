package cloudwatch

import (
	"code.cloudfoundry.org/lager"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/cloudwatch"
	"time"
)

func NewService(
	sess *session.Session,
	logger lager.Logger,
) CloudWatchService {
	return CloudWatchService{
		Client: cloudwatch.New(sess),
		Logger: logger.Session("cloudwatch-service"),
	}
}

func (cw *CloudWatchService) GetCDNMetricsForDistribution(
	distributionId string,
) ([]*cloudwatch.GetMetricStatisticsOutput, error) {
	metricNames := []metricMapping{
		{Name: "Requests", Statistic: "Sum"},
		{Name: "BytesDownloaded", Statistic: "Sum"},
		{Name: "BytesUploaded", Statistic: "Sum"},
		{Name: "4xxErrorRate", Statistic: "Average"},
		{Name: "5xxErrorRate", Statistic: "Average"},
		{Name: "TotalErrorRate", Statistic: "Average"},
	}

	var outputs []*cloudwatch.GetMetricStatisticsOutput
	period := time.Minute * 10
	endTime := time.Now()
	startTime := endTime.Add(-period)

	for _, mapping := range metricNames {

		cw.Logger.Info(
			"getting-metric-from-cloudwatch",
			lager.Data{
				"distribution-id": distributionId,
				"metric-name":     mapping.Name,
				"statistic":       mapping.Statistic,
				"start-time":      startTime.String(),
				"end-time":        endTime.String(),
				"period":          period.Seconds(),
			},
		)

		unit := aws.String("None")
		if mapping.Statistic == "Average" {
			unit = aws.String("Percent")
		}

		input := cloudwatch.GetMetricStatisticsInput{
			Dimensions: []*cloudwatch.Dimension{
				{
					Name:  aws.String("DistributionId"),
					Value: aws.String(distributionId),
				},
				{
					Name:  aws.String("Region"),
					Value: aws.String("Global"),
				},
			},
			EndTime:    aws.Time(endTime),
			MetricName: aws.String(mapping.Name),
			Namespace:  aws.String("AWS/CloudFront"),
			Period:     aws.Int64(int64(period.Seconds())),
			StartTime:  aws.Time(startTime),
			Statistics: []*string{aws.String(mapping.Statistic)},
			Unit:       unit,
		}

		output, err := cw.Client.GetMetricStatistics(&input)

		if err != nil {
			cw.Logger.Error("getting-metric-from-cloudwatch", err)
			return nil, err
		}

		outputs = append(outputs, output)
	}

	return outputs, nil
}
