package main

import (
	"encoding/json"
	"fmt"
	"os"
)

func getVCAPServiceCredentials(label string, credData interface{}) error {
	var allServices map[string][]struct {
		Credentials json.RawMessage `json:"credentials"`
	}

	err := json.Unmarshal([]byte(os.Getenv("VCAP_SERVICES")), &allServices)
	if err != nil {
		return err
	}

	services, ok := allServices[label]
	if !ok {
		return fmt.Errorf("Service %s not found in VCAP_SERVICES", label)
	}
	if len(services) < 1 {
		return fmt.Errorf("Service %s not found in VCAP_SERVICES", label)
	}
	return json.Unmarshal(services[0].Credentials, credData)
}
