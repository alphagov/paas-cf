package main

import (
	"bufio"
	"encoding/json"
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"sync"
	"time"

	portscanner "github.com/combor/port-scanner"
	"github.com/gorilla/mux"
)

const (
	timeout         = 20 * time.Millisecond
	portMin         = 1
	portMax         = 65535
	resultsFilename = "./results.json"
)

type ipList struct {
	Ips []string `json:"ips"`
}

type Result struct {
	Host        string `json:"host"`
	OpenedPorts []int  `json:"openedports"`
}

type Results struct {
	Results []Result `json:"results"`
}

func main() {
	var ips ipList
	var jsonData []byte
	iplist := flag.String("iplist", "./ips.json", "List of IPs to scan in json format")
	flag.Parse()
	if len(os.Args) == 1 {
		jsonData = []byte(os.Getenv("IP_LIST"))
		if jsonData == nil {
			log.Fatal("No iplist provided as file or IP_LIST env. Exiting...")
		}
	} else {
		var err error
		jsonData, err = ioutil.ReadFile(*iplist)
		if err != nil {
			log.Fatal("Can't read IPs file.")
		}
	}

	err := json.Unmarshal(jsonData, &ips)
	if err != nil {
		log.Fatal("Can't unmarshal IPs json")
	}
	mux := mux.NewRouter()
	mux.HandleFunc("/", renderResults)
	mux.HandleFunc("/triggerscan", triggerScan(ips))
	addr := ":" + os.Getenv("PORT")
	fmt.Println("Listening on", addr)
	err = http.ListenAndServe(addr, mux)
	if err != nil {
		log.Fatal(err)
	}
}

func saveResults(w http.ResponseWriter, r *http.Request, ips ipList) {
	resultsChan := scan(ips)
	var results Results
	for result := range resultsChan {
		results.Results = append(results.Results, result)
	}
	jsn, err := json.Marshal(results)
	if err != nil {
		log.Fatal("Can't marshal json")
	}
	f, err := os.Create(resultsFilename)
	defer f.Close()
	writer := bufio.NewWriter(f)
	writer.Write(jsn)
	writer.Flush()
}

func renderResults(w http.ResponseWriter, r *http.Request) {
	var jsonData []byte
	jsonData, err := ioutil.ReadFile(resultsFilename)
	if err != nil {
		jsonData = []byte("{}")
	}

	w.Header().Set("Content-Type", "application/json")
	w.Write(jsonData)
}

func triggerScan(ips ipList) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		go saveResults(w, r, ips)
		jsonData := []byte("{\"trigger\": true}")
		w.Header().Set("Content-Type", "application/json")
		w.Write(jsonData)
	}
}

func scan(ips ipList) <-chan Result {
	results := make(chan Result)
	go func() {
		var workers sync.WaitGroup
		for _, ip := range ips.Ips {
			workers.Add(1)
			go scanHost(ip, &workers, results)
		}
		go func() {
			workers.Wait()
			close(results)
		}()
	}()
	return results
}

func scanHost(host string, workers *sync.WaitGroup, results chan Result) {
	ps := portscanner.NewPortScanner(host, timeout)
	fmt.Printf("scanning %s:%d-%d %v\n", host, portMin, portMax, time.Now())
	openedPorts := ps.GetOpenedPort(portMin, portMax)
	results <- Result{host, openedPorts}
	fmt.Printf("done scanning %s:%d-%d %v\n", host, portMin, portMax, time.Now())
	workers.Done()
}
