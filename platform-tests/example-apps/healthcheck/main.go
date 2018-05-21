package main

import (
	"crypto/tls"
	"crypto/x509"
	"encoding/base64"
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
	http.HandleFunc("/mongo-test", mongoHandler)
	http.HandleFunc("/elasticsearch-test", elasticsearchHandler)
	http.HandleFunc("/redis-test", redisHandler)
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

func buildTLSConfigWithCACert(caCertBase64 string) (*tls.Config, error) {
	if caCertBase64 == "" {
		return &tls.Config{}, nil
	}

	ca, err := base64.StdEncoding.DecodeString(caCertBase64)
	if err != nil {
		return nil, err
	}
	roots := x509.NewCertPool()
	ok := roots.AppendCertsFromPEM(ca)
	if !ok {
		return nil, fmt.Errorf("Failed to parse CA certificate")
	}

	return &tls.Config{RootCAs: roots}, nil
}
