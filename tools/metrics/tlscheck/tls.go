package tlscheck

import (
	"crypto/tls"
	"crypto/x509"
	"fmt"
	"net"
	"strings"
)

func GetCertificate(addr string) (*x509.Certificate, error) {
	conn, err := tls.Dial("tcp", addr, nil)
	if err != nil {
		return nil, err
	}
	defer conn.Close()

	for _, chain := range conn.ConnectionState().VerifiedChains {
		for _, cert := range chain {
			if !cert.IsCA {
				return cert, nil
			}
		}
	}

	return nil, fmt.Errorf("no certificate found")
}

func IsCertificateError(err error) bool {
	switch v := err.(type) {
	case x509.CertificateInvalidError,
		x509.HostnameError,
		x509.SystemRootsError,
		x509.UnknownAuthorityError,
		x509.InsecureAlgorithmError:
		return true
	case *net.OpError:
		if v.Op == "remote error" && strings.Contains(err.Error(), "handshake failure") {
			return true // handshake error
		}
		return false
	default:
		return false
	}
}
