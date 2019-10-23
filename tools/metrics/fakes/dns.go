package fakes

import (
	"fmt"
	"log"

	"github.com/miekg/dns"
)

var (
	server *dns.Server
)

func ListenAndServeDNS(listenAddr string, records map[string][]string) error {
	server = &dns.Server{Addr: listenAddr, Net: "udp"}
	log.Println(fmt.Sprintf("created server to listen on %s", listenAddr))
	dns.HandleFunc(".", func(w dns.ResponseWriter, r *dns.Msg) {
		log.Println(fmt.Sprintf("handling lookup: %v", r))
		m := new(dns.Msg)
		m.SetReply(r)
		m.Compress = false

		switch r.Opcode {
		case dns.OpcodeQuery:
			for _, q := range m.Question {
				switch q.Qtype {
				case dns.TypeA:
					for _, ip := range records[q.Name] {
						rr, err := dns.NewRR(fmt.Sprintf("%s A %s", q.Name, ip))
						if err == nil {
							m.Answer = append(m.Answer, rr)
						}
					}
				}
			}
		}

		w.WriteMsg(m)
	})
	return server.ListenAndServe()
}

func ShutdownDNS() error {
	return server.Shutdown()
}
