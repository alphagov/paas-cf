package acceptance

import (
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("AWS", func() {
	It("should return CloudFront metrics", func() {
		Skip("Exporter does not always return these metrics, traffic dependent")

		Expect(metricFamilies).To(SatisfyAll(
			HaveKey("paas_aws_cloudfront_4xxerrorrate_ratio"),
			HaveKey("paas_aws_cloudfront_5xxerrorrate_ratio"),
			HaveKey("paas_aws_cloudfront_bytesdownloaded_bytes"),
			HaveKey("paas_aws_cloudfront_bytesuploaded_bytes"),
			HaveKey("paas_aws_cloudfront_requests"),
			HaveKey("paas_aws_cloudfront_totalerrorrate_ratio"),
		))
	})

	It("should return ElastiCache metrics", func() {
		Expect(metricFamilies).To(SatisfyAll(
			HaveKey("paas_aws_elasticache_cache_parameter_group_count"),
			HaveKey("paas_aws_elasticache_node_count"),
		))
	})

	It("should return ELB metrics", func() {
		Expect(metricFamilies).To(SatisfyAll(
			HaveKey("paas_aws_elb_healthy_node_count"),
			HaveKey("paas_aws_elb_unhealthy_node_count"),
		))
	})

	It("should return S3 metrics", func() {
		Expect(metricFamilies).To(SatisfyAll(
			HaveKey("paas_aws_s3_buckets_count"),
		))
	})
})
