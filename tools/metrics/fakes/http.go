package fakes

import (
	"net"
	"net/http"
	"time"
)

type httpHandler struct{}

func (h *httpHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	if q.Get("hang") == "true" {
		time.Sleep(1 * time.Hour)
		panic("giving up after hour of waiting")
	}
	w.WriteHeader(http.StatusTeapot)
}

func ListenAndServeHTTP(listenAddr string) *http.Server {
	server := &http.Server{Addr: listenAddr, Handler: &httpHandler{}}

	ln, err := net.Listen("tcp", listenAddr)
	if err != nil {
		return server
	}
	go server.Serve(ln)

	return server
}
