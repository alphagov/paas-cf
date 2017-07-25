package main

import (
	"crypto/tls"
	"crypto/x509"
	"database/sql"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"net"
	"net/http"
	"net/url"
	"os"
	"time"

	_ "github.com/go-sql-driver/mysql"
	_ "github.com/lib/pq"
	mgo "gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
)

func dbHandler(w http.ResponseWriter, r *http.Request) {
	ssl := r.FormValue("ssl") != "false"
	service := r.FormValue("service")

	err := testDBConnection(ssl, service)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	writeJson(w, map[string]interface{}{
		"success": true,
	})
}

func testDBConnection(ssl bool, service string) error {
	var err error
	var db *sql.DB

	if service == "" {
		service = "postgres"
	}

	switch service {
	case "mysql":
		dbu := os.Getenv("DATABASE_URL")
		db, err = mysqlOpen(dbu, ssl)
		if err != nil {
			return err
		}
		return testSQLConnection(db)
	case "postgres":
		dbu := os.Getenv("DATABASE_URL")
		db, err = postgresOpen(dbu, ssl)
		if err != nil {
			return err
		}
		return testSQLConnection(db)
	case "mongodb":
		vcap_services := os.Getenv("VCAP_SERVICES")
		credentials, err := mongoDBCredentials(vcap_services)
		if err != nil {
			return err
		}
		session, err := mongoDBOpen(credentials.URI, credentials.CACertificateBase64, ssl)
		if err != nil {
			return err
		}
		return testMongoDBConnection(session, credentials.Name)
	default:
		return fmt.Errorf("unknown service: " + service)
	}
}

func testSQLConnection(db *sql.DB) error {
	defer db.Close()

	_, err := db.Exec("CREATE TABLE foo(id integer)")
	if err != nil {
		return err
	}
	defer func() {
		db.Exec("DROP TABLE foo")
	}()

	_, err = db.Exec("INSERT INTO foo VALUES(42)")
	if err != nil {
		return err
	}

	var id int
	err = db.QueryRow("SELECT * FROM foo LIMIT 1").Scan(&id)
	if err != nil {
		return err
	}
	if id != 42 {
		return fmt.Errorf("Expected 42, got %d", id)
	}

	return nil
}

func postgresOpen(dbu string, ssl bool) (*sql.DB, error) {
	u, err := url.Parse(dbu)
	if err != nil {
		return nil, err
	}

	if ssl {
		u.RawQuery = "sslmode=verify-full"
	} else {
		u.RawQuery = "sslmode=disable"
	}

	return sql.Open("postgres", u.String())
}

func mysqlOpen(dbu string, ssl bool) (*sql.DB, error) {
	u, err := url.Parse(dbu)
	if err != nil {
		return nil, err
	}

	if ssl {
		u.RawQuery = "tls=true"
	} else {
		u.RawQuery = "tls=false"
	}

	connString := fmt.Sprintf("%s@tcp(%s:%s)%s?%s", u.User.String(), u.Hostname(), u.Port(), u.EscapedPath(), u.RawQuery)

	return sql.Open("mysql", connString)
}

func testMongoDBConnection(session *mgo.Session, db_name string) error {
	defer session.Close()

	type Person struct {
		Name  string
		Phone string
	}

	input := &Person{Name: "John Jones", Phone: "+447777777777"}
	db := session.DB(db_name).C("people")
	err := db.Insert(input)
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

func mongoDBCredentials(vcap_services_str string) (*Credentials, error) {
	type VCAPService struct {
		Credentials Credentials `json:"credentials"`
	}

	type VCAPServices struct {
		MongoDB []VCAPService `json:"mongodb"`
	}

	// Retrieve the MongoDB connection URI and the CA Certificate from the `VCAP_SERVICES`
	// environment variable.
	var vcap_services VCAPServices
	if err := json.Unmarshal([]byte(vcap_services_str), &vcap_services); err != nil {
		return nil, err
	}
	mongodb_credentials := vcap_services.MongoDB[0].Credentials
	return &mongodb_credentials, nil
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
	ca, err := base64.StdEncoding.DecodeString(ca_certificate_base64)
	if err != nil {
		return nil, err
	}
	roots := x509.NewCertPool()
	roots.AppendCertsFromPEM(ca)

	tlsConfig := &tls.Config{RootCAs: roots}
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

type Credentials struct {
	Name                string `json:"name"`
	URI                 string `json:"uri"`
	CACertificateBase64 string `json:"ca_certificate_base64"`
}
