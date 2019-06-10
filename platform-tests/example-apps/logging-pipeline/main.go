package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"time"
)

func main() {
	addr := ":" + os.Getenv("PORT")
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {

		message := fmt.Sprintf("Current time: %d", time.Now().Unix())

		w.Header().Set("Cache-Control", "max-age=0,no-store,no-cache")
		w.Header().Set("Content-Type", "text/plain")
		w.Write([]byte(message))

		log.Printf("Application responded with text: %s", message)
	})

	err := http.ListenAndServe(addr, nil)

	if err != nil {
		log.Fatal(err)
	}
}
