package emails

import (
	"github.com/alphagov/paas-cf/tools/user_emails/utils"
	"github.com/xenolf/lego/log"
	"os"
	"regexp"
)

type Csv struct {
	Email string `csv:"email"`
	Org string `csv:"org"`
	Role string `csv:"role"`
}

type userInfo struct {
	Username string
	Role string
}

var email_regex = regexp.MustCompile("^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$")

func FetchEmails(client Client, isCritical bool, isManagement bool) []Csv {
	orgs, err := client.ListOrgs()

	if err != nil {
		log.Fatal(err)
		return nil
	}

	var users []userInfo
	var usersIdentity map[userInfo]bool = map[userInfo]bool{}
	var userOrg []string
	data := []Csv{}

	status := utils.NewStatus(os.Stderr, false)
	for _, org := range orgs {
		status.Text(org.Name)
		switch isManagement {
		case false:
			switch isCritical {
			case false:
				u := normal(client, org.Guid)
				for _, usr := range u {
					if _, ok := usersIdentity[usr]; !ok {
						users = append(users, usr)
						usersIdentity[usr] = true
						userOrg = append(userOrg, org.Name)
						record := Csv{ Email: usr.Username, Org: org.Name, Role: usr.Role}
						data = append(data, record)
					}
				}
			case true:
				u := critical(client, org.Guid)
				for _, usr := range u {
					if _, ok := usersIdentity[usr]; !ok {
						users = append(users, usr)
						usersIdentity[usr] = true
						userOrg = append(userOrg, org.Name)
						record := Csv{ Email: usr.Username, Org: org.Name, Role: usr.Role}
						data = append(data, record)
					}
				}
			}
			status.Done()
		case true:
			u := management(client, org.Guid)
			for _, usr := range u {
				if _, ok := usersIdentity[usr]; !ok {
					users = append(users, usr)
					usersIdentity[usr] = true
					userOrg = append(userOrg, org.Name)
					record := Csv{ Email: usr.Username, Org: org.Name, Role: usr.Role}
					data = append(data, record)
				}
			}
		}
		status.Done()
	}

	return data
}

func validEmail(address string) bool {
	valid := email_regex.MatchString(address)
	return valid
}

func normal(client Client, orgs string ) []userInfo {
	var devs []userInfo

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
				data := userInfo{ Username: dev.Username, Role: "Developer"}
				devs = append(devs, data)
			}
		}
	}

	return devs
}

func critical(client Client, orgs string ) []userInfo {

	var users []userInfo

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
				data := userInfo{ Username: dev.Username, Role: "Developer"}
				users = append(users, data)
			}
		}
		spaceManagers, err := client.ListSpaceManagers(space.Guid)
		if err != nil {
			log.Fatal(err)
		}

		for _, manager := range spaceManagers {
			if validEmail(manager.Username) {
				data := userInfo{ Username: manager.Username, Role: "Space Manager"}
				users = append(users, data)
			}
		}
		spaceAuditors, err := client.ListSpaceAuditors(space.Guid)
		if err != nil {
			log.Fatal(err)
		}

		for _, auditor := range spaceAuditors {
			if validEmail(auditor.Username) {
				data := userInfo{ Username: auditor.Username, Role: "Space Auditor"}
				users = append(users, data)
			}
		}
		orgManagers, err := client.ListOrgManagers(orgs)
		if err != nil {
			log.Fatal(err)
		}

		for _, orgManager := range orgManagers {
			if validEmail(orgManager.Username) {
				data := userInfo{ Username: orgManager.Username, Role: "Org Manager"}
				users = append(users, data)
			}
		}
		orgAuditors, err := client.ListOrgAuditors(orgs)
		if err != nil {
			log.Fatal(err)
		}

		for _, orgAuditor := range orgAuditors {
			if validEmail(orgAuditor.Username) {
				data := userInfo{ Username: orgAuditor.Username, Role: "Org Auditor"}
				users = append(users, data)
			}
		}
	}

	return users
}

func management(client Client, orgs string) []userInfo {

	var users []userInfo

	orgManagers, err := client.ListOrgManagers(orgs)
	if err != nil {
		log.Fatal(err)
	}

	for _, orgManager := range orgManagers {
		if validEmail(orgManager.Username) {
			data := userInfo{ Username: orgManager.Username, Role: "Org Manager"}
			users = append(users, data)
		}
	}
	orgAuditors, err := client.ListOrgAuditors(orgs)
	if err != nil {
		log.Fatal(err)
	}

	for _, orgAuditor := range orgAuditors {
		if validEmail(orgAuditor.Username) {
			data := userInfo{ Username: orgAuditor.Username, Role: "Org Auditor"}
			users = append(users, data)
		}
	}

	orgBillingManagers, err := client.ListOrgBillingManagers(orgs)
	if err != nil {
		log.Fatal(err)
	}

	for _, orgBillingManager := range orgBillingManagers {
		if validEmail(orgBillingManager.Username) {
			data := userInfo{ Username: orgBillingManager.Username, Role: "Billing Manager"}
			users = append(users, data)
		}
	}
	return users

}