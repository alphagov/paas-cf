package main

import (
	"crypto/tls"
	"fmt"
	"net"
	"net/http"
	"net/url"
	"time"

	mgo "gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
)

func mongoHandler(w http.ResponseWriter, r *http.Request) {
	ssl := r.FormValue("ssl") != "false"

	err := testMongoDBConnection(ssl)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	writeJson(w, map[string]interface{}{
		"success": true,
	})
}

func testMongoDBConnection(ssl bool) error {
	var credentials struct {
		Name                string `json:"name"`
		URI                 string `json:"uri"`
		CACertificateBase64 string `json:"ca_certificate_base64"`
	}
	err := getVCAPServiceCredentials("mongodb", &credentials)
	if err != nil {
		return err
	}
	session, err := mongoDBOpen(credentials.URI, credentials.CACertificateBase64, ssl)
	if err != nil {
		return err
	}
	defer session.Close()

	type Person struct {
		Name  string
		Phone string
	}

	input := &Person{Name: "John Jones", Phone: "+447777777777"}
	db := session.DB(credentials.Name).C("people")
	err = db.Insert(input)
	if err != nil {
		return err
	}

	var result Person
	err = db.Find(bson.M{"name": "John Jones"}).One(&result)
	if err != nil {
		return err
	}
	if result.Name != input.Name {
		return fmt.Errorf("Name unexpectedly changed to %s in MongoDB test.", result.Name)
	}
	if result.Phone != input.Phone {
		return fmt.Errorf("Phone unexpectedly changed to %s in MongoDB test.", result.Phone)
	}
	return nil
}

func mongoDBOpen(db_url string, ca_certificate_base64 string, ssl bool) (*mgo.Session, error) {
	// This is work around for https://github.com/go-mgo/mgo/issues/84
	u, _ := url.Parse(db_url)
	values := u.Query()
	if _, ok := values["ssl"]; ok {
		delete(values, "ssl")
	}
	u.RawQuery = values.Encode()
	uri := u.String()

	mongourl, err := mgo.ParseURL(uri)
	if err != nil {
		return nil, err
	}

	if !ssl {
		session, err := mgo.DialWithTimeout(uri, 5*time.Second)
		if err != nil {
			return nil, err
		}
		return session, nil
	}

	// Compose has self-signed certs for mongo. Make sure we verify it against CA certificate provided in binding.
	tlsConfig, err := buildTLSConfigWithCACert(ca_certificate_base64)
	if err != nil {
		return nil, err
	}
	if tlsConfig.InsecureSkipVerify {
		return nil, fmt.Errorf("Verification was skipped.")
	}

	mongourl.DialServer = func(addr *mgo.ServerAddr) (net.Conn, error) {
		return tls.Dial("tcp", addr.String(), tlsConfig)
	}
	mongourl.Timeout = 10 * time.Second
	session, err := mgo.DialWithInfo(mongourl)
	if err != nil {
		return nil, err
	}

	return session, nil
}
