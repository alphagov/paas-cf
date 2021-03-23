package acceptance_test

import (
	"crypto/tls"
	"net"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/route53"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("The apps apex domain", func() {

	It("should resolve to the same ALB as the healthcheck app", func() {
		sess, err := session.NewSession()
		Expect(err).NotTo(HaveOccurred())

		svc := route53.New(sess)

		listHostedZonesByNameInput := &route53.ListHostedZonesByNameInput{
			DNSName: aws.String(GetConfigFromEnvironment("APPS_HOSTED_ZONE_NAME")),
		}
		listHostedZonesByNameOutput, err := svc.ListHostedZonesByName(listHostedZonesByNameInput)
		Expect(err).NotTo(HaveOccurred())

		zoneId := listHostedZonesByNameOutput.HostedZones[0].Id

		listResourceRecordSetsInput := &route53.ListResourceRecordSetsInput{
			HostedZoneId:    zoneId,
			StartRecordName: aws.String(testConfig.GetAppsDomain()),
			StartRecordType: aws.String("A"),
			MaxItems:        aws.String("1"),
		}

		listResourceRecordSetsOutput, err := svc.ListResourceRecordSets(listResourceRecordSetsInput)
		Expect(err).NotTo(HaveOccurred())
		Expect(*listResourceRecordSetsOutput.ResourceRecordSets[0].Name).To(Equal(testConfig.GetAppsDomain() + "."))
		Expect(*listResourceRecordSetsOutput.ResourceRecordSets[0].Type).To(Equal("A"))

		apexAlbDomain := *listResourceRecordSetsOutput.ResourceRecordSets[0].AliasTarget.DNSName

		healthcheckAlbDomain, err := net.LookupCNAME("healthcheck." + testConfig.GetAppsDomain())
		Expect(err).NotTo(HaveOccurred())

		Expect(apexAlbDomain).To(Equal(healthcheckAlbDomain))
	})

	It("should have a valid TLS certificate with the apps domain as SAN", func() {
		conn, err := tls.Dial("tcp", testConfig.GetAppsDomain()+":443", nil)
		Expect(err).NotTo(HaveOccurred())
		defer conn.Close()
		peerCertificates := conn.ConnectionState().PeerCertificates
		Expect(len(peerCertificates)).To(BeNumerically(">", 0))
		cert := peerCertificates[0]
		Expect(cert.DNSNames).To(ContainElement(testConfig.GetAppsDomain()))
	})

})
