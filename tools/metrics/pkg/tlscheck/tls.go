package tlscheck

import (
	"crypto/tls"
	"crypto/x509"
	"fmt"
	"time"
)

type TLSChecker struct{}

//go:generate counterfeiter -o fakes/fake_cert_checker.go . CertChecker
type CertChecker interface {
	DaysUntilExpiry(string, *tls.Config) (float64, error)
	CertificateAuthority(string, *tls.Config) (string, error)
}

func (tc *TLSChecker) DaysUntilExpiry(addr string, tlsConfig *tls.Config) (float64, error) {
	cert, err := GetCertificate(addr, tlsConfig)
	if err == nil {
		return time.Until(cert.NotAfter).Hours() / 24, nil
	}

	switch e := err.(type) {
	case x509.CertificateInvalidError:
		if e.Reason == x509.Expired {
			return 0, nil
		}
	}

	return 0, err
}

func (tc *TLSChecker) CertificateAuthority(addr string, tlsConfig *tls.Config) (string, error) {
	cert, err := GetCertificate(addr, tlsConfig)

	if err == nil {
		return cert.Issuer.CommonName, nil
	}

	switch e := err.(type) {
	case x509.CertificateInvalidError:
		if e.Reason == x509.Expired {
			return cert.Issuer.CommonName, nil
		}
	}

	return "", err

}

func GetCertificate(addr string, tlsConfig *tls.Config) (*x509.Certificate, error) {
	conn, err := tls.Dial("tcp", addr, tlsConfig)
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
