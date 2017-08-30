package cfclient

import (
	"net/url"
	"testing"
	"time"

	. "github.com/smartystreets/goconvey/convey"
)

func TestListTasks(t *testing.T) {
	Convey("List Tasks", t, func() {
		mocks := []MockRoute{
			{"GET", "/v3/tasks", listTasksPayload, "", 200, "", nil},
		}
		setupMultiple(mocks, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		task, err := client.ListTasks()
		So(err, ShouldBeNil)

		So(len(task), ShouldEqual, 2)

		So(task[0].GUID, ShouldEqual, "xxxxxxxx-e99c-4d60-xxx-e066eb45f8a7")
		So(task[0].State, ShouldEqual, "FAILED")
		So(task[0].SequenceID, ShouldEqual, 1)
		So(task[0].MemoryInMb, ShouldEqual, 1024)
		So(task[0].DiskInMb, ShouldEqual, 1024)
		So(task[0].CreatedAt.String(), ShouldEqual, time.Date(2016, 12, 22, 13, 24, 20, 0, time.FixedZone("UTC", 0)).String())

		So(task[1].GUID, ShouldEqual, "xxxxxxxx-5a25-4110-xxx-b309dc5cb0aa")
		So(task[1].State, ShouldEqual, "FAILED")
		So(task[1].SequenceID, ShouldEqual, 2)
		So(task[1].MemoryInMb, ShouldEqual, 1024)
		So(task[1].DiskInMb, ShouldEqual, 1024)
		So(task[1].CreatedAt.String(), ShouldEqual, time.Date(2016, 12, 22, 13, 24, 36, 0, time.FixedZone("UTC", 0)).String())
	})
}
func TestListTasksByQuery(t *testing.T) {
	Convey("List Tasks", t, func() {
		mocks := []MockRoute{
			{"GET", "/v3/tasks", listTasksPayload, "", 200, "names=my-fancy-name&page=1", nil},
		}
		setupMultiple(mocks, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		query := url.Values{}
		query.Add("names", "my-fancy-name")
		query.Add("page", "1")
		task, err := client.ListTasksByQuery(query)
		So(err, ShouldBeNil)

		So(len(task), ShouldEqual, 2)

		So(task[0].GUID, ShouldEqual, "xxxxxxxx-e99c-4d60-xxx-e066eb45f8a7")
		So(task[0].State, ShouldEqual, "FAILED")
		So(task[0].SequenceID, ShouldEqual, 1)
		So(task[0].MemoryInMb, ShouldEqual, 1024)
		So(task[0].DiskInMb, ShouldEqual, 1024)
		So(task[0].CreatedAt.String(), ShouldEqual, time.Date(2016, 12, 22, 13, 24, 20, 0, time.FixedZone("UTC", 0)).String())

		So(task[1].GUID, ShouldEqual, "xxxxxxxx-5a25-4110-xxx-b309dc5cb0aa")
		So(task[1].State, ShouldEqual, "FAILED")
		So(task[1].SequenceID, ShouldEqual, 2)
		So(task[1].MemoryInMb, ShouldEqual, 1024)
		So(task[1].DiskInMb, ShouldEqual, 1024)
		So(task[1].CreatedAt.String(), ShouldEqual, time.Date(2016, 12, 22, 13, 24, 36, 0, time.FixedZone("UTC", 0)).String())
	})
}

func TestCreateTask(t *testing.T) {
	Convey("Create Task", t, func() {
		mocks := []MockRoute{
			{"POST", "/v3/apps/740ebd2b-162b-469a-bd72-3edb96fabd9a/tasks", createTaskPayload, "", 201, "", nil},
		}
		setupMultiple(mocks, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		tr := TaskRequest{
			Command:          "rake db:migrate",
			Name:             "migrate",
			MemoryInMegabyte: 512,
			DiskInMegabyte:   1024,
			DropletGUID:      "740ebd2b-162b-469a-bd72-3edb96fabd9a",
		}
		task, err := client.CreateTask(tr)
		So(err, ShouldBeNil)

		So(task.Command, ShouldEqual, "rake db:migrate")
		So(task.Name, ShouldEqual, "migrate")
		So(task.DiskInMb, ShouldEqual, 1024)
		So(task.MemoryInMb, ShouldEqual, 512)
		So(task.DropletGUID, ShouldEqual, "740ebd2b-162b-469a-bd72-3edb96fabd9a")
	})
}

func TestTerminateTask(t *testing.T) {
	Convey("Terminate Task", t, func() {
		mocks := []MockRoute{
			{"PUT", "/v3/tasks/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/cancel", "", "", 202, "", nil},
		}
		setupMultiple(mocks, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		errTerm := client.TerminateTask("xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx")
		So(errTerm, ShouldBeNil)
	})
}

func TestGetTask(t *testing.T) {
	Convey("Create Task", t, func() {
		mocks := []MockRoute{
			{"GET", "/v3/tasks/740ebd2b-162b-469a-bd72-3edb96fabd9a", createTaskPayload, "", 200, "", nil},
		}
		setupMultiple(mocks, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		task, err := client.GetTaskByGuid("740ebd2b-162b-469a-bd72-3edb96fabd9a")
		So(err, ShouldBeNil)

		So(task.Command, ShouldEqual, "rake db:migrate")
		So(task.Name, ShouldEqual, "migrate")
		So(task.DiskInMb, ShouldEqual, 1024)
		So(task.MemoryInMb, ShouldEqual, 512)
		So(task.DropletGUID, ShouldEqual, "740ebd2b-162b-469a-bd72-3edb96fabd9a")
	})
}

func TestTasksByApp(t *testing.T) {
	Convey("List Tasks by App", t, func() {
		mocks := []MockRoute{
			{"GET", "/v3/apps/ccc25a0f-c8f4-4b39-9f1b-de9f328d0ee5/tasks", listTasksPayload, "", 200, "", nil},
		}
		setupMultiple(mocks, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		task, err := client.TasksByApp("ccc25a0f-c8f4-4b39-9f1b-de9f328d0ee5")
		So(err, ShouldBeNil)

		So(len(task), ShouldEqual, 2)

		So(task[0].GUID, ShouldEqual, "xxxxxxxx-e99c-4d60-xxx-e066eb45f8a7")
		So(task[0].State, ShouldEqual, "FAILED")
		So(task[0].SequenceID, ShouldEqual, 1)
		So(task[0].MemoryInMb, ShouldEqual, 1024)
		So(task[0].DiskInMb, ShouldEqual, 1024)
		So(task[0].CreatedAt.String(), ShouldEqual, time.Date(2016, 12, 22, 13, 24, 20, 0, time.FixedZone("UTC", 0)).String())

		So(task[1].GUID, ShouldEqual, "xxxxxxxx-5a25-4110-xxx-b309dc5cb0aa")
		So(task[1].State, ShouldEqual, "FAILED")
		So(task[1].SequenceID, ShouldEqual, 2)
		So(task[1].MemoryInMb, ShouldEqual, 1024)
		So(task[1].DiskInMb, ShouldEqual, 1024)
		So(task[1].CreatedAt.String(), ShouldEqual, time.Date(2016, 12, 22, 13, 24, 36, 0, time.FixedZone("UTC", 0)).String())
	})
}

func TestTasksByAppByQuery(t *testing.T) {
	Convey("List Tasks by App", t, func() {
		mocks := []MockRoute{
			{"GET", "/v3/apps/ccc25a0f-c8f4-4b39-9f1b-de9f328d0ee5/tasks", listTasksPayload, "", 200, "names=my-fancy-name&page=1", nil},
		}
		setupMultiple(mocks, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		query := url.Values{}
		query.Add("names", "my-fancy-name")
		query.Add("page", "1")
		task, err := client.TasksByAppByQuery("ccc25a0f-c8f4-4b39-9f1b-de9f328d0ee5", query)
		So(err, ShouldBeNil)

		So(len(task), ShouldEqual, 2)

		So(task[0].GUID, ShouldEqual, "xxxxxxxx-e99c-4d60-xxx-e066eb45f8a7")
		So(task[0].State, ShouldEqual, "FAILED")
		So(task[0].SequenceID, ShouldEqual, 1)
		So(task[0].MemoryInMb, ShouldEqual, 1024)
		So(task[0].DiskInMb, ShouldEqual, 1024)
		So(task[0].CreatedAt.String(), ShouldEqual, time.Date(2016, 12, 22, 13, 24, 20, 0, time.FixedZone("UTC", 0)).String())

		So(task[1].GUID, ShouldEqual, "xxxxxxxx-5a25-4110-xxx-b309dc5cb0aa")
		So(task[1].State, ShouldEqual, "FAILED")
		So(task[1].SequenceID, ShouldEqual, 2)
		So(task[1].MemoryInMb, ShouldEqual, 1024)
		So(task[1].DiskInMb, ShouldEqual, 1024)
		So(task[1].CreatedAt.String(), ShouldEqual, time.Date(2016, 12, 22, 13, 24, 36, 0, time.FixedZone("UTC", 0)).String())
	})
}
