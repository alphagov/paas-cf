package cfclient

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestListServiceKeys(t *testing.T) {
	Convey("List Service Keys", t, func() {
		setup(MockRoute{"GET", "/v2/service_keys", listServiceKeysPayload, "", 200, "", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		serviceKeys, err := client.ListServiceKeys()
		So(err, ShouldBeNil)

		So(len(serviceKeys), ShouldEqual, 2)
		So(serviceKeys[0].Guid, ShouldEqual, "3b933598-64ed-4613-a0f5-b7e8c0379368")
		So(serviceKeys[0].Name, ShouldEqual, "RedisMonitoringKey")
		So(serviceKeys[0].ServiceInstanceGuid, ShouldEqual, "ad98f310-a3a0-47aa-9116-f8295d41a9b2")
		So(serviceKeys[0].Credentials, ShouldNotEqual, nil)
		So(serviceKeys[0].ServiceInstanceUrl, ShouldEqual, "/v2/service_instances/ad98f310-a3a0-47aa-9116-f8295d41a9b2")
		So(serviceKeys[1].Guid, ShouldEqual, "8be3911b-c621-4467-8866-f8b924aaee57")
		So(serviceKeys[1].Name, ShouldEqual, "test01_key")
		So(serviceKeys[1].ServiceInstanceGuid, ShouldEqual, "ecf26687-e176-4784-b181-b3c942fecb62")
		So(serviceKeys[1].Credentials, ShouldNotEqual, nil)
		m := serviceKeys[1].Credentials.(map[string]interface{})
		So(m["uri"], ShouldEqual, "nhp://100.100.100.100:9008")
		So(serviceKeys[1].ServiceInstanceUrl, ShouldEqual, "/v2/service_instances/fcf26687-e176-4784-b181-b3c942fecb62")
	})
}

func TestGetServiceKeyByName(t *testing.T) {
	Convey("Get service key by name", t, func() {
		setup(MockRoute{"GET", "/v2/service_keys", getServiceKeyPayload, "", 200, "q=name:test01_key", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		serviceKey, err := client.GetServiceKeyByName("test01_key")
		So(err, ShouldBeNil)

		So(serviceKey, ShouldNotBeNil)
		So(serviceKey.Name, ShouldEqual, "test01_key")
		So(serviceKey.ServiceInstanceGuid, ShouldEqual, "ecf26687-e176-4784-b181-b3c942fecb62")
		So(serviceKey.Credentials, ShouldNotEqual, nil)
		So(serviceKey.ServiceInstanceUrl, ShouldEqual, "/v2/service_instances/ecf26687-e176-4784-b181-b3c942fecb62")
	})
}

func TestGetServiceKeyByGuid(t *testing.T) {
	Convey("Get service key by guid", t, func() {
		setup(MockRoute{"GET", "/v2/service_keys", getServiceKeyPayload, "", 200, "q=service_instance_guid:ecf26687-e176-4784-b181-b3c942fecb62", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		serviceKey, err := client.GetServiceKeyByInstanceGuid("ecf26687-e176-4784-b181-b3c942fecb62")
		So(err, ShouldBeNil)

		So(serviceKey, ShouldNotBeNil)
		So(serviceKey.Name, ShouldEqual, "test01_key")
		So(serviceKey.ServiceInstanceGuid, ShouldEqual, "ecf26687-e176-4784-b181-b3c942fecb62")
		So(serviceKey.Credentials, ShouldNotEqual, nil)
		So(serviceKey.ServiceInstanceUrl, ShouldEqual, "/v2/service_instances/ecf26687-e176-4784-b181-b3c942fecb62")
	})
}

func TestGetServiceKeysByGuid(t *testing.T) {
	Convey("Get service key by guid", t, func() {
		setup(MockRoute{"GET", "/v2/service_keys", getServiceKeysPayload, "", 200, "q=service_instance_guid:ecf26687-e176-4784-b181-b3c942fecb62", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		serviceKeys, err := client.GetServiceKeysByInstanceGuid("ecf26687-e176-4784-b181-b3c942fecb62")
		So(err, ShouldBeNil)
		So(len(serviceKeys), ShouldEqual, 2)

		So(serviceKeys[0].Name, ShouldEqual, "test01_key")
		So(serviceKeys[0].ServiceInstanceGuid, ShouldEqual, "ecf26687-e176-4784-b181-b3c942fecb62")
		So(serviceKeys[0].Credentials, ShouldNotEqual, nil)
		So(serviceKeys[0].ServiceInstanceUrl, ShouldEqual, "/v2/service_instances/ecf26687-e176-4784-b181-b3c942fecb62")

		So(serviceKeys[1].Name, ShouldEqual, "test02_key")
		So(serviceKeys[1].ServiceInstanceGuid, ShouldEqual, "ecf26687-e176-4784-b181-b3c942fecb62")
		So(serviceKeys[1].Credentials, ShouldNotEqual, nil)
		So(serviceKeys[1].ServiceInstanceUrl, ShouldEqual, "/v2/service_instances/ecf26687-e176-4784-b181-b3c942fecb62")
	})
}

func TestCreateServiceKey(t *testing.T) {
	Convey("Create a service key succeeds", t, func() {
		setup(MockRoute{"POST", "/v2/service_keys", postServiceKeysPayload, "", 201, "", nil}, t)
		defer teardown()

		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		csr := CreateServiceKeyRequest{
			Name:                "key1",
			ServiceInstanceGuid: "ecf26687-e176-4784-b181-b3c942fecb62",
		}

		key, err := client.CreateServiceKey(csr)
		So(err, ShouldBeNil)

		So(key.Name, ShouldEqual, "key1")
		So(key.ServiceInstanceUrl, ShouldEqual, "/v2/service_instances/ecf26687-e176-4784-b181-b3c942fecb62")
	})

	Convey("Create a service key with parameters succeeds", t, func() {
		setup(MockRoute{"POST", "/v2/service_keys", postServiceKeysPayload, "", 201, "", nil}, t)
		defer teardown()

		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		csr := CreateServiceKeyRequest{
			Name:                "key1",
			ServiceInstanceGuid: "ecf26687-e176-4784-b181-b3c942fecb62",
			Parameters: map[string]interface{}{
				"read-only":   true,
				"username":    "user1",
				"connections": 6,
			},
		}

		_, err = client.CreateServiceKey(csr)
		So(err, ShouldBeNil)
	})

	Convey("Delete a service key succeeds", t, func() {
		setup(MockRoute{"DELETE", "/v2/service_keys/ecf26687-e176-4784-b181-b3c942fecb62", "", "", 200, "", nil}, t)
		defer teardown()

		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		err = client.DeleteServiceKey("ecf26687-e176-4784-b181-b3c942fecb62")
		So(err, ShouldBeNil)
	})

	Convey("Create a duplicate service key", t, func() {
		setup(MockRoute{"POST", "/v2/service_keys", postServiceKeysDuplicatePayload, "", 400, "", nil}, t)
		defer teardown()

		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		csr := CreateServiceKeyRequest{
			Name:                "key1",
			ServiceInstanceGuid: "ecf26687-e176-4784-b181-b3c942fecb62",
		}

		key, err := client.CreateServiceKey(csr)
		So(err.Error(), ShouldEqual, "cfclient error (CF-ServiceKeyNameTaken|360001): The service key name is taken: key1")

		So(key.Name, ShouldEqual, "")
	})

	Convey("Gets a bad JSON response", t, func() {
		setup(MockRoute{"POST", "/v2/service_keys", postServiceKeysBadPayload, "", 201, "", nil}, t)
		defer teardown()

		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		csr := CreateServiceKeyRequest{
			Name:                "key1",
			ServiceInstanceGuid: "ecf26687-e176-4784-b181-b3c942fecb62",
		}

		key, err := client.CreateServiceKey(csr)
		So(err.Error(), ShouldEqual, "unexpected end of JSON input")

		So(key.Name, ShouldEqual, "")
	})

	Convey("Gets an unexpected HTTP status code", t, func() {
		setup(MockRoute{"POST", "/v2/service_keys", "", "", 202, "", nil}, t)
		defer teardown()

		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		csr := CreateServiceKeyRequest{
			Name:                "key1",
			ServiceInstanceGuid: "ecf26687-e176-4784-b181-b3c942fecb62",
		}

		key, err := client.CreateServiceKey(csr)
		So(err.Error(), ShouldEqual, "CF API returned with status code 202")

		So(key.Name, ShouldEqual, "")
	})
}
