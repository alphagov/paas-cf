package main

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"net/url"
	"os"

	_ "github.com/lib/pq"
)

func main() {
	addr := ":" + os.Getenv("PORT")
	fmt.Println("Listening on", addr)
	http.HandleFunc("/", staticHandler)
	http.HandleFunc("/db", dbHandler)
	err := http.ListenAndServe(addr, nil)
	if err != nil {
		log.Fatal(err)
	}
}

func staticHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Cache-Control", "max-age=0,no-store,no-cache")
	http.ServeFile(w, r, "static/"+r.URL.Path[1:])
}

func dbHandler(w http.ResponseWriter, r *http.Request) {
	ssl := r.FormValue("ssl") != "false"

	err := testDBConnection(ssl)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	writeJson(w, map[string]interface{}{
		"success": true,
	})
}

func writeJson(w http.ResponseWriter, data interface{}) {
	output, err := json.MarshalIndent(data, "", "  ")
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	w.Header().Set("Cache-Control", "max-age=0,no-store,no-cache")
	w.Header().Set("Content-Type", "application/json")
	w.Write(output)
}

func testDBConnection(ssl bool) error {
	dbURL, err := url.Parse(os.Getenv("DATABASE_URL"))
	if err != nil {
		return err
	}
	if ssl {
		dbURL.RawQuery = dbURL.RawQuery + "&sslmode=verify-full"
	} else {
		dbURL.RawQuery = dbURL.RawQuery + "&sslmode=disable"
	}

	db, err := sql.Open("postgres", dbURL.String())
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
