package main

import (
	"database/sql"
	"fmt"
	"net/http"
	"net/url"
	"os"

	_ "github.com/lib/pq"
)

const (
	permissionCheckTableName = "permissions_check"
)

func dbPermissionsCheckHandler(w http.ResponseWriter, r *http.Request) {
	var err error

	phase := r.FormValue("phase")
	switch phase {
	case "setup":
		err = setupPermissionsCheck()
	case "test":
		err = testPermissionsCheck()
	default:
		http.Error(w, fmt.Sprintf("Invalid phase '%s' in request.", phase), http.StatusBadRequest)
		return
	}
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	writeJson(w, map[string]interface{}{
		"success": true,
	})
}

func setupPermissionsCheck() error {
	dbURL, err := url.Parse(os.Getenv("DATABASE_URL"))
	if err != nil {
		return err
	}
	db, err := sql.Open("postgres", dbURL.String())
	if err != nil {
		return err
	}
	defer db.Close()

	_, err = db.Exec("CREATE TABLE " + permissionCheckTableName + "(id integer)")
	if err != nil {
		return fmt.Errorf("Error creating table: %s", err.Error())
	}
	_, err = db.Exec("INSERT INTO " + permissionCheckTableName + " VALUES(42)")
	if err != nil {
		return fmt.Errorf("Error inserting record: %s", err.Error())
	}

	return nil
}

func testPermissionsCheck() error {
	dbURL, err := url.Parse(os.Getenv("DATABASE_URL"))
	if err != nil {
		return err
	}
	db, err := sql.Open("postgres", dbURL.String())
	if err != nil {
		return err
	}
	defer db.Close()

	// Can we write?
	_, err = db.Exec("INSERT INTO " + permissionCheckTableName + " VALUES(43)")
	if err != nil {
		return fmt.Errorf("Error inserting record: %s", err.Error())
	}

	// Can we ALTER?
	_, err = db.Exec("ALTER TABLE " + permissionCheckTableName + " ADD COLUMN something INTEGER")
	if err != nil {
		return fmt.Errorf("Error ALTERing table: %s", err.Error())
		return err
	}

	// Can we DROP?
	_, err = db.Exec("DROP TABLE " + permissionCheckTableName)
	if err != nil {
		return fmt.Errorf("Error DROPing table: %s", err.Error())
	}

	return nil
}
