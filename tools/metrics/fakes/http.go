package fakes

import "net/http"

type httpHandler struct{}

func (h *httpHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusTeapot)
}

func ListenAndServeHTTP(listenAddr string) *http.Server {
	server := &http.Server{Addr: listenAddr, Handler: &httpHandler{}}
	go server.ListenAndServe()
	return server
}
