package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
)

func main() {
	addr := ":" + os.Getenv("PORT")
	fmt.Println("Listening on", addr)
	http.HandleFunc("/", staticHandler)
	http.HandleFunc("/db", dbHandler)
	http.HandleFunc("/opensearch-test", opensearchHandler)
	http.HandleFunc("/influxdb-test", influxdbHandler)
	http.HandleFunc("/redis-test", redisHandler)
	http.HandleFunc("/s3-test", s3Handler)
	http.HandleFunc("/sqs-test", sqsHandler)
	err := http.ListenAndServe(addr, nil)
	if err != nil {
		log.Fatal(err)
	}
}

func staticHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Cache-Control", "max-age=0,no-store,no-cache")
	http.ServeFile(w, r, "static/"+r.URL.Path[1:])
}

func writeJson(w http.ResponseWriter, data interface{}) {
	output, err := json.MarshalIndent(data, "", "  ")
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	w.Header().Set("Cache-Control", "max-age=0,no-store,no-cache")
	w.Header().Set("Content-Type", "application/json")
	w.Write(output)
}
