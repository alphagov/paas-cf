package emails

import (
	"github.com/alphagov/paas-cf/tools/user_emails/utils"
	"github.com/xenolf/lego/log"
	"os"
	"regexp"
)


var email_regex = regexp.MustCompile("^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$")

func FetchEmails(client Client, isCritical bool) []string {
	orgs, err := client.ListOrgs()

	if err != nil {
		log.Fatal(err)
		return nil
	}

	var users []string
	var usersIdentity map[string]bool = map[string]bool{}

	status := utils.NewStatus(os.Stderr, false)
	for _, org := range orgs {
		status.Text(org.Name)
		switch isCritical {
		case false:
			u := normal(client, org.Guid)
			for _, usr := range u {
				if _, ok := usersIdentity[usr]; !ok{
					users = append(users, usr)
					usersIdentity[usr] = true
				}
			}
		case true:
			u := critical(client, org.Guid)
			for _, usr := range u {
				if _, ok := usersIdentity[usr]; !ok{
					users = append(users, usr)
					usersIdentity[usr] = true
				}
			}
		}
		status.Done()
	}

	return users
}

func validEmail(address string) bool {
	valid := email_regex.MatchString(address)
	return valid
}

func normal(client Client, orgs string ) []string {
	var devs []string

	targetOrg := map[string] []string {
		"organization_guid": []string{ orgs },
	}
	spaces, err := client.ListSpacesByQuery(targetOrg)
	if err != nil {
		log.Fatal(err)
	}
	for _, space := range spaces {
		spaceDevs, err := client.ListSpaceDevelopers(space.Guid)
		if err != nil {
			log.Fatal(err)
		}

		for _, dev := range spaceDevs {
			if validEmail(dev.Username) {
				devs = append(devs, dev.Username)
			}
		}
	}

	return devs
}

func critical(client Client, orgs string ) []string  {

	var users []string

	targetOrg := map[string] []string {
		"organization_guid": []string{ orgs },
	}
	spaces, err := client.ListSpacesByQuery(targetOrg)
	if err != nil {
		log.Fatal(err)
	}
	for _, space := range spaces {
		spaceDevs, err := client.ListSpaceDevelopers(space.Guid)
		if err != nil {
			log.Fatal(err)
		}

		for _, dev := range spaceDevs {
			if validEmail(dev.Username) {
				users = append(users, dev.Username)
			}
		}
		spaceManagers, err := client.ListSpaceManagers(space.Guid)
		if err != nil {
			log.Fatal(err)
		}

		for _, manager := range spaceManagers {
			if validEmail(manager.Username) {
				users = append(users, manager.Username)
			}
		}
		spaceAuditors, err := client.ListSpaceAuditors(space.Guid)
		if err != nil {
			log.Fatal(err)
		}

		for _, auditor := range spaceAuditors {
			if validEmail(auditor.Username) {
				users = append(users, auditor.Username)
			}
		}
		orgManagers, err := client.ListOrgManagers(orgs)
		if err != nil {
			log.Fatal(err)
		}

		for _, orgManager := range orgManagers {
			if validEmail(orgManager.Username) {
				users = append(users, orgManager.Username)
			}
		}
		orgAuditors, err := client.ListOrgAuditors(orgs)
		if err != nil {
			log.Fatal(err)
		}

		for _, orgAuditor := range orgAuditors {
			if validEmail(orgAuditor.Username) {
				users = append(users, orgAuditor.Username)
			}
		}
	}

	return users

}
