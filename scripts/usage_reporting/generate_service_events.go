package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"net/url"
	"os"
	"time"

	"github.com/cloudfoundry-community/go-cfclient"
)

func main() {
	var (
		org      = flag.String("org", "", "Org GUID to report on")
		start    = flag.String("start", "", "RFC3339 date to start reporting on")
		finish   = flag.String("finish", "", "RFC3339 date to finish reporting on")
		api      = flag.String("api", "", "API URL")
		token    = flag.String("token", "", "oAuth token")
		insecure = flag.Bool("insecure", false, "Disable TLS verify")
	)

	flag.Parse()

	startTime, err := time.Parse(time.RFC3339, *start)
	if err != nil {
		log.Fatal(err)
	}
	finishTime, err := time.Parse(time.RFC3339, *finish)
	if err != nil {
		log.Fatal(err)
	}

	client, err := cfclient.NewClient(
		&cfclient.Config{
			ApiAddress:        *api,
			Token:             *token,
			SkipSslValidation: *insecure,
		},
	)
	if err != nil {
		log.Fatal(err)
	}

	query := url.Values{}
	query.Set("q", fmt.Sprintf("organization_guid:%s", *org))
	services, err := client.ListServiceInstancesByQuery(query)
	if err != nil {
		log.Fatal(err)
	}

	plans, err := client.ListServicePlans()
	if err != nil {
		log.Fatal(err)
	}
	plansByGuid := map[string]cfclient.ServicePlan{}
	for _, plan := range plans {
		plansByGuid[plan.Guid] = plan
	}

	spacesByGuid := map[string]string{}
	usageEvents := []UsageEvent{}
	for _, service := range services {
		if _, ok := spacesByGuid[service.SpaceGuid]; !ok {
			space, err := client.GetSpaceByGuid(service.SpaceGuid)
			if err != nil {
				log.Fatal(err)
			}

			spacesByGuid[service.SpaceGuid] = space.Name
		}

		event := UsageEvent{
			Entity: Entity{
				State:               "CREATED",
				OrgGuid:             *org,
				SpaceGuid:           service.SpaceGuid,
				SpaceName:           spacesByGuid[service.SpaceGuid],
				ServiceInstanceGuid: service.Guid,
				ServiceInstanceName: service.Name,
				ServiceInstanceType: service.Type,
				ServiceLabel:        "probably postgres",
				ServicePlanName:     plansByGuid[service.ServicePlanGuid].Name,
			},
			MetaData: MetaData{
				CreatedAt: startTime,
			},
		}

		usageEvents = append(usageEvents, event)
		event.Entity.State = "DELETED"
		event.MetaData.CreatedAt = finishTime
		usageEvents = append(usageEvents, event)
	}

	encoder := json.NewEncoder(os.Stdout)
	if err := encoder.Encode(&usageEvents); err != nil {
		log.Println(err)
	}
}
