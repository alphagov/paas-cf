package api_availability

import (
	"fmt"
	"time"

	"github.com/cloudfoundry-community/go-cfclient"
)

const (
	numWorkers = 16
)

type Report struct {
	Successes int64
	Failures  int64
	Errors    map[*Task]map[string]int // number of errors by error message by task
	Elapsed   time.Duration
}

func (r *Report) String() string {
	s := "\nReport:\n"
	s += "==============\n"
	s += fmt.Sprintf("Total task executions: %d\n", r.Successes+r.Failures)
	s += fmt.Sprintf("Total Successes: %d\n", r.Successes)
	s += fmt.Sprintf("Total failures: %d\n", r.Failures)
	s += fmt.Sprintf("Elaspsed time: %s\n", r.Elapsed.String())
	s += fmt.Sprintf("Average rate: %.2f tasks/sec\n", float64(r.Successes+r.Failures)/r.Elapsed.Seconds())

	if len(r.Errors) > 0 {
		s += fmt.Sprintf("\nErrors:\n")
		for task, errCounts := range r.Errors {
			s += fmt.Sprintf("\n    %s:\n", task.name)
			for err, count := range errCounts {
				s += fmt.Sprintf("        %s (%d failures)\n", err, count)
			}
		}
	}
	return s
}

type TaskFunc func(cf *cfclient.Client) error

type Task struct {
	name string
	fn   TaskFunc
}

type result struct {
	task    *Task
	err     error
	started time.Time
	ended   time.Time
}

// Monitor continuously runs each Task given to Add in parallel
// and gathers basic statistics on
type Monitor struct {
	tasks     []*Task
	reporter  chan *Report
	queue     chan *Task
	results   chan *result
	halt      chan bool
	clientCfg *cfclient.Config
}

func (m *Monitor) Add(name string, fn TaskFunc) {
	m.tasks = append(m.tasks, &Task{
		name: name,
		fn:   fn,
	})
}

func (m *Monitor) statsCollector() {
	report := &Report{
		Errors: map[*Task]map[string]int{},
	}
	started := time.Now()
	for {
		select {
		case result := <-m.results:

			err := result.err
			if err != nil {
				msg := err.Error()
				if report.Errors[result.task] == nil {
					report.Errors[result.task] = map[string]int{}
				}
				report.Errors[result.task][msg]++
				report.Failures++
				fmt.Printf(
					"%s - %s %s: %s\n",
					result.started.Format("2006-01-02 15:04:05.00 MST"),
					result.ended.Format("2006-01-02 15:04:05.00 MST"),
					result.task.name,
					msg,
				)
			} else {
				report.Successes++
			}
		case <-m.halt:
			report.Elapsed = time.Since(started)
			m.reporter <- report
			return
		}
	}
}

// Run launches N worker routines to continually execute tasks and blocks until Stop is called
func (m *Monitor) Run() *Report {
	if m.halt != nil {
		panic("Run() called twice")
	}
	m.queue = make(chan *Task, numWorkers)
	m.halt = make(chan bool)
	for i := 0; i < numWorkers; i++ {
		go m.worker()
	}
	go m.statsCollector()
	go m.producer()
	return <-m.reporter
}

// worker executes a task from the queue and sends the result to the statsCollector
func (m *Monitor) worker() {
	for {
		select {
		case task := <-m.queue:
			res := &result{
				task:    task,
				started: time.Now(),
			}
			res.err = func() error {
				var cfg = *m.clientCfg
				cf, err := cfclient.NewClient(&cfg)
				if err != nil {
					return err
				}
				return task.fn(cf)
			}()
			res.ended = time.Now()
			m.results <- res
		case <-m.halt:
			return
		}
	}
}

// producer continually fills the queue with tasks
func (m *Monitor) producer() {
	for {
		for _, task := range m.tasks {
			select {
			case <-m.halt:
				return
			default:
				m.queue <- task
			}
		}
	}
}

func (m *Monitor) Stop() {
	select {
	case <-m.halt:
		return
	default:
		close(m.halt)
	}
}

func NewMonitor(clientCfg *cfclient.Config) *Monitor {
	m := &Monitor{
		reporter:  make(chan *Report),
		results:   make(chan *result, numWorkers),
		clientCfg: clientCfg,
	}
	return m
}
