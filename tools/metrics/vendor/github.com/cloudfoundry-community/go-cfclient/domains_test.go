package cfclient

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestListDomains(t *testing.T) {
	Convey("List domains", t, func() {
		setup(MockRoute{"GET", "/v2/private_domains", listDomainsPayload, "", 200, "", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		domains, err := client.ListDomains()
		So(err, ShouldBeNil)

		So(len(domains), ShouldEqual, 4)
		So(domains[0].Guid, ShouldEqual, "b2a35f0c-d5ad-4a59-bea7-461711d96b0d")
		So(domains[0].Name, ShouldEqual, "vcap.me")
		So(domains[0].OwningOrganizationGuid, ShouldEqual, "4cf3bc47-eccd-4662-9322-7833c3bdcded")
		So(domains[0].OwningOrganizationUrl, ShouldEqual, "/v2/organizations/4cf3bc47-eccd-4662-9322-7833c3bdcded")
		So(domains[0].SharedOrganizationsUrl, ShouldEqual, "/v2/private_domains/b2a35f0c-d5ad-4a59-bea7-461711d96b0d/shared_organizations")
	})
}

func TestListSharedDomains(t *testing.T) {
	Convey("List shared domains", t, func() {
		setup(MockRoute{"GET", "/v2/shared_domains", listSharedDomainsPayload, "", 200, "", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		domains, err := client.ListSharedDomains()
		So(err, ShouldBeNil)

		So(len(domains), ShouldEqual, 1)
		So(domains[0].Guid, ShouldEqual, "91977695-8ad9-40db-858f-4df782603ec3")
		So(domains[0].Name, ShouldEqual, "domain-49.example.com")
		So(domains[0].RouterGroupGuid, ShouldEqual, "my-random-guid")
		So(domains[0].RouterGroupType, ShouldEqual, "tcp")
	})
}

func TestGetDomainByName(t *testing.T) {
	Convey("Get domain by name", t, func() {
		setup(MockRoute{"GET", "/v2/private_domains", listDomainsPayload, "", 200, "q=name:vcap.me", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		domain, err := client.GetDomainByName("vcap.me")
		So(err, ShouldBeNil)

		So(domain.Guid, ShouldEqual, "b2a35f0c-d5ad-4a59-bea7-461711d96b0d")
		So(domain.Name, ShouldEqual, "vcap.me")
	})
	Convey("Get domain by name with an endpoint that returns a 404", t, func() {
		setup(MockRoute{"GET", "/v2/private_domains", listDomainsEmptyResponse, "", 404, "q=name:vcap.me", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		_, listErr := client.GetDomainByName("vcap.me")
		So(listErr, ShouldNotBeNil)
	})
	Convey("Get domain by name for a non-existing domain", t, func() {
		setup(MockRoute{"GET", "/v2/private_domains", listDomainsEmptyResponse, "", 200, "q=name:idontexist", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		_, listErr := client.GetDomainByName("idontexist")
		So(listErr, ShouldNotBeNil)
	})
}

func TestGetSharedDomainByName(t *testing.T) {
	Convey("Get shared domain by name", t, func() {
		setup(MockRoute{"GET", "/v2/shared_domains", listSharedDomainsPayload, "", 200, "q=name:domain-49.example.com", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		domain, err := client.GetSharedDomainByName("domain-49.example.com")
		So(err, ShouldBeNil)

		So(domain.Guid, ShouldEqual, "91977695-8ad9-40db-858f-4df782603ec3")
		So(domain.Name, ShouldEqual, "domain-49.example.com")
	})
	Convey("Get shared domain by name with an endpoint that returns a 404", t, func() {
		setup(MockRoute{"GET", "/v2/shared_domains", listDomainsEmptyResponse, "", 404, "q=name:domain-49.example.com", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		_, listErr := client.GetSharedDomainByName("domain-49.example.com")
		So(listErr, ShouldNotBeNil)
	})
	Convey("Get shared domain by name for a non-existing domain", t, func() {
		setup(MockRoute{"GET", "/v2/shared_domains", listDomainsEmptyResponse, "", 200, "q=name:idontexist", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		_, listErr := client.GetSharedDomainByName("idontexist")
		So(listErr, ShouldNotBeNil)
	})
}

func TestCreateDomain(t *testing.T) {
	Convey("Create domain", t, func() {
		setup(MockRoute{"POST", "/v2/private_domains", postDomainPayload, "", 201, "", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		domain, err := client.CreateDomain("exmaple.com", "8483e4f1-d3a3-43e2-ab8c-b05ea40ef8db")
		So(err, ShouldBeNil)

		So(domain.Guid, ShouldEqual, "b98aeca1-22b9-49f9-8428-3ace9ea2ba11")
	})
}

func TestDeleteDomain(t *testing.T) {
	Convey("Delete domain", t, func() {
		setup(MockRoute{"DELETE", "/v2/private_domains/b2a35f0c-d5ad-4a59-bea7-461711d96b0d", "", "", 204, "", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		err = client.DeleteDomain("b2a35f0c-d5ad-4a59-bea7-461711d96b0d")
		So(err, ShouldBeNil)
	})
}
