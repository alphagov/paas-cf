package main

import (
	"log"
	"net/http"
	"os"
	"time"
)

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8082"
	}
	addr := ":" + port

	upstream := os.Getenv("UPSTREAM")
	if upstream == "" {
		upstream = "http://localhost:8081"
	}

	http.DefaultClient.Timeout = 5 * time.Second

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		var code int
		resp, err := http.Get(upstream)
		if err == nil {
			code = resp.StatusCode
		} else {
			log.Printf("Error %s when requesting upstream %s\n", err, upstream)
		}

		w.Header().Set("Content-Type", "text/plain")
		w.Header().Set("Cache-Control", "max-age=0,no-store,no-cache")

		if code == http.StatusOK {
			w.WriteHeader(http.StatusOK)
			w.Write([]byte("OK"))
			log.Println("code=200 upstream=200")
		} else {
			w.WriteHeader(http.StatusServiceUnavailable)
			w.Write([]byte("KO"))
			log.Printf("code=503 upstream=%d", code)
		}
	})

	log.Printf("Upstream is %s\n", upstream)
	log.Printf("Listening on %s\n", addr)
	err := http.ListenAndServe(addr, nil)
	if err != nil {
		log.Fatal(err)
	}
}
