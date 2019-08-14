package main

import (
	"encoding/json"
	"io/ioutil"
)

func GetPlanGUIDS(filename string) (map[string]string, error) {
	var plans map[string]string
	b, err := ioutil.ReadFile(filename)
	if err != nil {
		return plans, err
	}

	err = json.Unmarshal(b, &plans)
	if err != nil {
		return plans, err
	}

	return plans, nil
}
