package main

import (
	"database/sql"
	"fmt"
	"net/http"
	"net/url"
	"os"

	_ "github.com/go-sql-driver/mysql"
	_ "github.com/lib/pq"
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

	dbu := os.Getenv("DATABASE_URL")

	if service == "" {
		service = "postgres"
	}

	switch service {
	case "mysql":
		db, err = mysqlOpen(dbu, ssl)
	case "postgres":
		db, err = postgresOpen(dbu, ssl)
	default:
		return fmt.Errorf("unknown service: " + service)
	}
	if err != nil {
		return err
	}
	defer db.Close()

	_, err = db.Exec("CREATE TABLE foo(id integer)")
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
