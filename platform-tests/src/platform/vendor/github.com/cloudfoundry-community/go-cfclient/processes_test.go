package cfclient

import (
	"net/url"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestListProcesses(t *testing.T) {
	Convey("List Processes", t, func() {
		mocks := []MockRoute{
			{"GET", "/v3/processes", listProcessesPayload1, "", 200, "per_page=20", nil},
			{"GET", "/v3/processesPage2", listProcessesPayload2, "", 200, "page=2&per_page=20", nil},
		}
		setupMultiple(mocks, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		q := url.Values{}
		q.Add("per_page", "20")
		procs, err := client.ListAllProcessesByQuery(q)
		So(err, ShouldBeNil)

		So(procs, ShouldHaveLength, 26)
	})
}
