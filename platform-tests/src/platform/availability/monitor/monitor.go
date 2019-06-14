package monitor

import (
	"fmt"
	"io"
	"regexp"
	"time"

	"github.com/cloudfoundry-community/go-cfclient"
)

type TaskFunc func(cfg *cfclient.Config) error

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
	tasks             []*Task
	taskRatePerSecond int64
	reporter          chan *Report
	queue             chan *Task
	results           chan *result
	halt              chan bool
	clientCfg         *cfclient.Config
	logger            io.Writer
	numWorkers        int
	warningMatchers   []*regexp.Regexp
	targetReliability float64
}

func (m *Monitor) Add(name string, fn TaskFunc) {
	m.tasks = append(m.tasks, &Task{
		name: name,
		fn:   fn,
	})
}

func (m *Monitor) statsCollector() {
	report := &Report{
		Errors:   map[*Task]map[string]int{},
		Warnings: map[*Task]map[string]int{},
	}
	started := time.Now()
	for {
		select {
		case result := <-m.results:

			err := result.err
			if err != nil {
				msg := err.Error()

				ignored := false
				for _, warningMatcher := range m.warningMatchers {
					if warningMatcher.MatchString(msg) {
						ignored = true
						break
					}
				}
				if !ignored {
					if report.Errors[result.task] == nil {
						report.Errors[result.task] = map[string]int{}
					}
					report.Errors[result.task][msg]++
					report.FailureCount++
				} else {
					if report.Warnings[result.task] == nil {
						report.Warnings[result.task] = map[string]int{}
					}
					report.Warnings[result.task][msg]++
					report.WarningCount++
				}
				fmt.Fprintf(
					m.logger,
					"%s - %s %s: %s\n",
					result.started.Format("2006-01-02 15:04:05.00 MST"),
					result.ended.Format("2006-01-02 15:04:05.00 MST"),
					result.task.name,
					msg,
				)
			} else {
				report.SuccessCount++
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
	m.queue = make(chan *Task, m.numWorkers)
	m.halt = make(chan bool)
	for i := 0; i < m.numWorkers; i++ {
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
				return task.fn(&cfg)
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
			case <-time.After(m.taskRateToDuration()):
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

func (m *Monitor) taskRateToDuration() time.Duration {
	return time.Second / time.Duration(m.taskRatePerSecond)
}

func (m *Monitor) HaveTestsPassed(r Report) bool {
	if m.targetReliability == 0.0 {
		return false // targetReliability has not been set, always fail
	}

	if r.TotalExecutions() == 0 {
		return false // tests should fail if they don't execute anything
	}

	return m.targetReliability <= r.PercentageGoodExecutions()
}

func NewMonitor(
	clientCfg *cfclient.Config,
	logger io.Writer,
	numWorkers int,
	warningMatchers []*regexp.Regexp,
	taskRatePerSecond int64,
	targetReliability float64,
) *Monitor {
	m := &Monitor{
		reporter:          make(chan *Report),
		results:           make(chan *result, numWorkers),
		clientCfg:         clientCfg,
		numWorkers:        numWorkers,
		warningMatchers:   warningMatchers,
		logger:            logger,
		taskRatePerSecond: taskRatePerSecond,
		targetReliability: targetReliability,
	}
	return m
}
