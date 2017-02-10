package scripts_test

import (
	"net/http"
	"os"
	"os/exec"
	"strings"
	"time"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"

	"github.com/onsi/gomega/gbytes"
	"github.com/onsi/gomega/gexec"
	"github.com/onsi/gomega/ghttp"
)

var _ = Describe("UpdateDataDogMonitor", func() {

	var (
		timeOut                = 5 * time.Second
		cmdInput               string
		requireFullWindowFalse = `
{
    "version": 3,
    "terraform_version": "0.7.3",
    "serial": 5,
    "lineage": "bfa4e77c-4e4e-462e-92a9-dba07be0f409",
    "modules": [
        {
            "path": [
                "root"
            ],
            "outputs": {},
			"resources": {
				"datadog_monitor.continuous-smoketests-failures": {
					"type": "datadog_monitor",
					"depends_on": [],
					"primary": {
						"id": "1",
						"attributes": {
							"escalation_message": "Test",
							"id": "1",
							"message": "Test",
							"name": "Fake monitor",
							"notify_no_data": "false",
							"query": "fake_query",
							"require_full_window": "false",
							"tags.%": "2",
							"tags.deployment": "fake_tag",
							"tags.service": "fake_monitors",
							"thresholds.%": "1",
							"thresholds.critical": "3",
							"type": "metric alert"
						},
						"meta": {},
						"tainted": false
					},
					"deposed": [],
					"provider": ""
				}
			},
			"depends_on": []
		}
	]
}
			`
		requireFullWindowTrue = `
{
    "version": 3,
    "terraform_version": "0.7.3",
    "serial": 5,
    "lineage": "bfa4e77c-4e4e-462e-92a9-dba07be0f409",
    "modules": [
        {
            "path": [
                "root"
            ],
            "outputs": {},
			"resources": {
				"datadog_monitor.continuous-smoketests-failures": {
					"type": "datadog_monitor",
					"depends_on": [],
					"primary": {
						"id": "1",
						"attributes": {
							"escalation_message": "Test",
							"id": "1",
							"message": "Test",
							"name": "Fake monitor",
							"notify_no_data": "false",
							"query": "fake_query",
							"require_full_window": "true",
							"tags.%": "2",
							"tags.deployment": "fake_tag",
							"tags.service": "fake_monitors",
							"thresholds.%": "1",
							"thresholds.critical": "3",
							"type": "metric alert"
						},
						"meta": {},
						"tainted": false
					},
					"deposed": [],
					"provider": ""
				}
			},
			"depends_on": []
		}
	]
}
			`
		session *gexec.Session
		server  *ghttp.Server

		respJsonPut = []byte(`{
  "tags": [
    "deployment:fake",
    "service:fake"
  ],
  "deleted": null,
  "query": "fake query",
  "message": "fake message",
  "id": 1,
  "multi": false,
  "name": "concourse continuous smoketests failures",
  "created": "1970-00-00T00:00:01.000000+00:00",
  "created_at": 1,
  "creator": {
    "id": 1,
    "handle": "fake.email@fake.com",
    "name": "Mr Fake",
    "email": "fake.email.@fake.com"
  },
  "org_id": 1,
  "modified": "1970-00-00T00:00:02.000000+00:00",
  "state": {
    "groups": {}
  },
  "overall_state": "No Data",
  "type": "query alert",
  "options": {
    "notify_audit": false,
    "locked": false,
    "silenced": {},
    "thresholds": {
      "critical": 3
    },
    "require_full_window": false,
    "new_host_delay": 300,
    "notify_no_data": false,
    "escalation_message": "Smoke test failures"
  }
}`)

		respJsonGet = []byte(`{
  "tags": [
    "deployment:fake",
    "service:fake"
  ],
  "deleted": null,
  "query": "fake query",
  "message": "fake message",
  "id": 1,
  "multi": false,
  "name": "concourse continuous smoketests failures",
  "created": "1970-00-00T00:00:01.000000+00:00",
  "created_at": 1,
  "creator": {
    "id": 1,
    "handle": "fake.email@fake.com",
    "name": "Mr Fake",
    "email": "fake.email.@fake.com"
  },
  "org_id": 1,
  "modified": "1970-00-00T00:00:02.000000+00:00",
  "state": {
    "groups": {}
  },
  "overall_state": "No Data",
  "type": "query alert",
  "options": {
    "notify_audit": false,
    "locked": false,
    "silenced": {},
    "thresholds": {
      "critical": 3
    },
    "new_host_delay": 300,
    "notify_no_data": false,
    "escalation_message": "Smoke test failures"
  }
}`)
	)

	BeforeEach(func() {
		server = ghttp.NewServer()
	})

	AfterEach(func() {
		server.Close()
	})

	JustBeforeEach(func() {
		os.Setenv("TF_VAR_datadog_api_key", "aaaaaaaaaaaaa")
		os.Setenv("TF_VAR_datadog_app_key", "bbbbbbbbbbbbb")
		command := exec.Command("bundle", "exec", "./update_monitor_options.rb", server.URL())
		command.Stdin = strings.NewReader(cmdInput)

		var err error
		session, err = gexec.Start(command, GinkgoWriter, GinkgoWriter)
		Expect(err).ToNot(HaveOccurred())
	})

	Context("when the require_full_window option is set to false", func() {
		BeforeEach(func() {
			cmdInput = requireFullWindowFalse
			server.RouteToHandler("GET", "/api/v1/monitor/1", ghttp.RespondWith(http.StatusOK, respJsonGet))
			server.RouteToHandler("PUT", "/api/v1/monitor/1", ghttp.RespondWith(http.StatusOK, respJsonPut))
		})

		It("updates the monitor and preserves all options", func() {
			Eventually(session, timeOut).Should(gexec.Exit(0))
			Expect(session.Out).To(gbytes.Say("Updated monitor 1 with attributes {\"notify_audit\"=>false, \"locked\"=>false, \"silenced\"=>{}, \"thresholds\"=>{\"critical\"=>3}, \"new_host_delay\"=>300, \"notify_no_data\"=>false, \"escalation_message\"=>\"Smoke test failures\", \"require_full_window\"=>false}\n"))
		})
	})

	Context("when the require_full_window option is set to true", func() {
		BeforeEach(func() {
			cmdInput = requireFullWindowTrue
			server.RouteToHandler("GET", "/api/v1/monitor/1", ghttp.RespondWith(http.StatusOK, respJsonGet))
			server.RouteToHandler("PUT", "/api/v1/monitor/1", ghttp.RespondWith(http.StatusOK, respJsonPut))
		})

		It("doesn't update the monitor", func() {
			Eventually(session, timeOut).Should(gexec.Exit(0))
			Expect(session.Out.Contents()).To(BeEmpty())
		})
	})

	Context("when API responds with non 200 code to GET monitor", func() {
		BeforeEach(func() {
			cmdInput = requireFullWindowFalse
			server.RouteToHandler("GET", "/api/v1/monitor/1", ghttp.RespondWith(http.StatusInternalServerError, nil))
		})

		It("exits with non 0 code", func() {
			Eventually(session, timeOut).Should(gexec.Exit(1))
		})
	})
	Context("when API responds with non 200 code to PUT monitor", func() {
		BeforeEach(func() {
			cmdInput = requireFullWindowFalse
			server.RouteToHandler("GET", "/api/v1/monitor/1", ghttp.RespondWith(http.StatusOK, respJsonGet))
			server.RouteToHandler("PUT", "/api/v1/monitor/1", ghttp.RespondWith(http.StatusInternalServerError, nil))
		})

		It("exits with non 0 code", func() {
			Eventually(session, timeOut).Should(gexec.Exit(1))
		})
	})
})
