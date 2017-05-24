package main

import (
	"crypto/tls"
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"math/rand"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"
)

const (
	delay   = 250 * time.Millisecond
	letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

	BYTE     = int64(1)
	KILOBYTE = 1024 * BYTE
	MEGABYTE = 1024 * KILOBYTE
	GIGABYTE = 1024 * MEGABYTE
	TERABYTE = 1024 * GIGABYTE
)

func main() {
	addr := ":" + os.Getenv("PORT")
	fmt.Println("Listening on", addr)
	http.HandleFunc("/", root)
	http.HandleFunc("/print-headers", printHeaders)
	http.HandleFunc("/body-size", bodySize)
	http.HandleFunc("/header-size", headerSize)
	http.HandleFunc("/big-header", bigHeader)
	http.HandleFunc("/egress", egress)
	http.HandleFunc("/slow-response", slowResponse)
	http.HandleFunc("/slow-request", slowRequest)
	http.HandleFunc("/long-url", longURL)
	err := http.ListenAndServe(addr, nil)
	if err != nil {
		log.Fatal(err)
	}
}

func root(w http.ResponseWriter, r *http.Request) {
	w.Write([]byte("OK"))
}

func printHeaders(w http.ResponseWriter, r *http.Request) {
	jsonData, err := json.Marshal(r.Header)
	if err != nil {
		http.Error(w, fmt.Sprint(err), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.Write(jsonData)
}

func bodySize(w http.ResponseWriter, r *http.Request) {
	body, err := ioutil.ReadAll(r.Body)
	if err != nil {
		http.Error(w, fmt.Sprint(err), http.StatusInternalServerError)
		return
	}
	w.Write([]byte(fmt.Sprintf("%d", len(body))))
}

func headerSize(w http.ResponseWriter, r *http.Request) {
	header := r.Header.Get("test-header")
	w.Write([]byte(fmt.Sprintf("%d", len(header))))
}

func bigHeader(w http.ResponseWriter, r *http.Request) {

	var headerSize = r.URL.Query().Get("size")
	headerInt, err := strconv.Atoi(headerSize)
	if err != nil {
		http.Error(w, fmt.Sprint(err), http.StatusInternalServerError)
		return
	}

	w.Header().Set("test-header", randStringBytes(headerInt*int(KILOBYTE)))
}

func egress(w http.ResponseWriter, r *http.Request) {

	domain := r.URL.Query().Get("domain")

	var responseMessage string
	var responseCode int
	tr := &http.Transport{
		TLSClientConfig: &tls.Config{InsecureSkipVerify: true},
	}
	httpClient := &http.Client{Transport: tr}

	req, err := http.NewRequest("GET", fmt.Sprintf("https://%s/", domain), nil)
	if err != nil {
		http.Error(w, fmt.Sprint(err), http.StatusInternalServerError)
		return
	}
	egressResponse, err := httpClient.Do(req)

	if err != nil {
		http.Error(w, fmt.Sprint(err), http.StatusInternalServerError)
		return
	}

	responseCode = egressResponse.StatusCode
	if egressResponse.StatusCode != 200 {
		responseMessage = "ERROR"
	} else {
		responseMessage = "OK"
	}
	w.WriteHeader(responseCode)
	w.Write([]byte(responseMessage))
}

type slowReader struct{ r io.Reader }

func (r slowReader) Read(data []byte) (int, error) {
	time.Sleep(delay)
	n, err := r.r.Read(data[:1])
	return n, err
}

func slowResponse(w http.ResponseWriter, r *http.Request) {
	var text = r.URL.Query().Get("text")
	s := strings.NewReader(text)
	t := slowReader{s}
	w.Header().Set("Content-Type", "text/html")
	_, err := io.Copy(w, t)
	if err != nil {
		return
	}
}

func slowRequest(w http.ResponseWriter, r *http.Request) {
	reqStart := time.Now()

	w.Write([]byte("OK"))
	requestDuration := time.Since(reqStart)
	fmt.Println("Request took:", requestDuration)
}

func longURL(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "text/html")
	w.Write([]byte(r.URL.RawQuery))
}

func randStringBytes(n int) string {
	rand.Seed(time.Now().UnixNano())
	b := make([]byte, n)
	for i := range b {
		b[i] = letters[rand.Intn(len(letters))]
	}
	return string(b)
}
