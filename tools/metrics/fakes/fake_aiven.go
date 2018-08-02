package fakes

import (
	"net/http"
	"net/http/httptest"
	"fmt"
)

type FakeAivenServer struct {
	Server *httptest.Server
	Mux *http.ServeMux
}

func NewFakeAivenServer(validToken string) (aivenServer *FakeAivenServer) {
	mux := http.NewServeMux()

	mux.HandleFunc("/project/test/invoice", func(w http.ResponseWriter, r *http.Request) {
		auth:= r.Header.Get("Authorization")
		validTokenHeader := fmt.Sprintf("aivenv1 %s", validToken )
		if auth != validTokenHeader {
			w.WriteHeader(http.StatusForbidden)
		} else {
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusOK)

			w.Write([]byte(`
			{
				"invoices": [
					{
						"currency": "GBP",
						"download_cookie": "123456789",
						"invoice_number": "2dd1-1",
						"period_begin": "2018-07-01T00:00:00Z",
						"period_end": "2018-07-31T23:59:59Z",
						"state": "mailed",
						"total_inc_vat": "76.90",
						"total_vat_zero": "64.08"
					},
					{
						"currency": "GBP",
						"download_cookie": "123456790",
						"invoice_number": "2dd1-2",
						"period_begin": "2018-08-01T00:00:00Z",
						"period_end": "2018-08-01T23:59:59Z",
						"state": "estimate",
						"total_inc_vat": "13.06",
						"total_vat_zero": "10.88"
					}
				]
			}
			`))
		}
	})

	return &FakeAivenServer{
		Mux:        mux,
		Server:     httptest.NewServer(mux),
	}
}
