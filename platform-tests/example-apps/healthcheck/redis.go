package main

import (
	"fmt"
	"net/http"

	"github.com/garyburd/redigo/redis"
	"github.com/pkg/errors"
)

func redisHandler(w http.ResponseWriter, r *http.Request) {
	err := testRedisConnection()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	writeJson(w, map[string]interface{}{
		"success": true,
	})
}

func testRedisConnection() error {
	var credentials struct {
		URI string `json:"uri"`
	}

	err := getVCAPServiceCredentials("redis", &credentials)
	if err != nil {
		return errors.Wrap(err, "failed to parse VCAP_SERVICES")
	}

	conn, err := redis.DialURL(credentials.URI)
	if err != nil {
		return errors.Wrap(err, "failed to connect to Redis")
	}
	defer conn.Close()

	_, err = conn.Do("SET", "hello", "world")
	if err != nil {
		return errors.Wrap(err, "failed to SET")
	}

	redisValue, err := redis.String(conn.Do("GET", "hello"))
	if err != nil {
		return errors.Wrap(err, "failed to GET")
	}
	if redisValue != "world" {
		return fmt.Errorf("expected \"world\" got %s", redisValue)
	}

	return nil
}
