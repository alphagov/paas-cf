package main

import (
	"fmt"
	"net/http"
	"net/url"
	"time"

	influxdbclient "github.com/influxdata/influxdb1-client"
)

func influxdbHandler(w http.ResponseWriter, r *http.Request) {
	err := testInfluxDBConnection()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	writeJson(w, map[string]interface{}{
		"success": true,
	})
}

func testInfluxDBConnection() error {
	const (
		database        = "defaultdb"
		measurement     = "acceptance_test_meas"
		retentionPolicy = "default_retention_policy"
	)

	testRun := fmt.Sprintf("%x", time.Now().Unix())

	var credentials struct {
		URI string `json:"uri"`
	}

	err := getVCAPServiceCredentials("influxdb", &credentials)
	if err != nil {
		return err
	}

	u, err := url.Parse(credentials.URI)
	if err != nil {
		return err
	}
	if u.User == nil {
		return fmt.Errorf("Expected Userinfo on URL, but was nil")
	}

	username := u.User.Username()
	if username == "" {
		return fmt.Errorf("Expected username in URL, but was empty")
	}

	password, present := u.User.Password()
	if !present || password == "" {
		return fmt.Errorf("Expected password in URL, but was empty")
	}

	cfg := &influxdbclient.Config{
		URL:      *u,
		Username: username,
		Password: password,
	}

	conn, err := influxdbclient.NewClient(*cfg)
	if err != nil {
		return err
	}

	// Ping the database
	_, _, err = conn.Ping()
	if err != nil {
		return err
	}

	// Show databases
	showQuery := influxdbclient.Query{
		Command: "SHOW DATABASES",
	}
	showResp, err := conn.Query(showQuery)
	if err != nil {
		return err
	}
	if showResp.Error() != nil {
		return fmt.Errorf("Error creating database: %s", showResp.Error())
	}

	batch := influxdbclient.BatchPoints{
		Database:        database,
		RetentionPolicy: retentionPolicy,

		Points: []influxdbclient.Point{
			influxdbclient.Point{
				Measurement: measurement,

				Fields: map[string]interface{}{
					"test_run": testRun,
				},
			},
		},
	}
	writeResp, err := conn.Write(batch)
	if err != nil {
		return fmt.Errorf("Failed to write points: %s %+v", err, writeResp)
	}

	readResp, err := conn.Query(influxdbclient.Query{
		Database: database,

		Command: fmt.Sprintf(
			`SELECT time, test_run FROM %s WHERE test_run = '%s'`,
			measurement, testRun,
		),
	})
	if err != nil {
		return fmt.Errorf(
			"Error reading test data: %s %+v",
			err, readResp,
		)
	}

	readResult := readResp.Results[0]
	if len(readResult.Series) != 1 {
		return fmt.Errorf(
			"Read %d results, expected 1, response: %+v",
			len(readResult.Series), readResp,
		)
	}

	readSerie := readResult.Series[0]
	if len(readSerie.Values) != 1 {
		return fmt.Errorf(
			"Read %d values, expected a 1 value [[time, test_run]], response: %+v",
			len(readSerie.Values), readResp,
		)
	}

	readTestRun := fmt.Sprintf("%s", readSerie.Values[0][1])
	if readTestRun != testRun {
		return fmt.Errorf(
			"Read %s, expected %s, response: %+v",
			readTestRun, testRun, readResp,
		)
	}

	return nil
}
