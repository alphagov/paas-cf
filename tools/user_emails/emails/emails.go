package emails

import (
	"github.com/alphagov/paas-cf/tools/user_emails/utils"
	"github.com/xenolf/lego/log"
	"os"
	"regexp"
	"strings"
)

type UserDetails struct {
	Email string `csv:"email"`
	Org string `csv:"org"`
	OrgId string `csv:"org_id"`
	Role string `csv:"role"`
	Admin string `csv:"admin"`
	Region string `csv:"region"`
}

type userInfo struct {
	Username string
	Role string
	Admin string
	Region string
}

var email_regex = regexp.MustCompile("^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$")

func FetchEmails(client Client, isCritical bool, isManagement bool, adminEndpoint string, region string) []UserDetails {
	orgs, err := client.ListOrgs()

	if err != nil {
		log.Fatal(err)
		return nil
	}

	var users []userInfo
	var usersIdentity map[userInfo]bool = map[userInfo]bool{}
	data := []UserDetails{}

	status := utils.NewStatus(os.Stderr, false)
	for _, org := range orgs {
		status.Text(org.Name)
		switch isManagement {
		case false:
			switch isCritical {
			case false:
				u := normal(client, org.Guid, adminEndpoint, region)
				for _, usr := range u {
					if _, ok := usersIdentity[usr]; !ok {
						users = append(users, usr)
						usersIdentity[usr] = true
						record := UserDetails{ Email: usr.Username, Org: org.Name, OrgId: org.Guid, Role: usr.Role, Admin: usr.Admin, Region: usr.Region}
						data = append(data, record)
					}
				}
			case true:
				u := critical(client, org.Guid, adminEndpoint, region)
				for _, usr := range u {
					if _, ok := usersIdentity[usr]; !ok {
						users = append(users, usr)
						usersIdentity[usr] = true
						record := UserDetails{ Email: usr.Username, Org: org.Name, OrgId: org.Guid, Role: usr.Role, Admin: usr.Admin, Region: usr.Region}
						data = append(data, record)
					}
				}
			}
			status.Done()
		case true:
			u := management(client, org.Guid, adminEndpoint, region)
			for _, usr := range u {
				if _, ok := usersIdentity[usr]; !ok {
					users = append(users, usr)
					usersIdentity[usr] = true
					record := UserDetails{ Email: usr.Username, Org: org.Name, OrgId: org.Guid, Role: usr.Role, Admin: usr.Admin, Region: usr.Region}
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

func normal(client Client, orgs string, adminEndpoint string, region string ) []userInfo {
	var devs []userInfo

	targetOrg := map[string] []string {
		"organization_guid": { orgs },
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
				pazmin := strings.Join([]string{adminEndpoint, orgs},"")
				data := userInfo{ Username: dev.Username, Role: "Developer", Admin: pazmin, Region: region}
				devs = append(devs, data)
			}
		}
	}

	return devs
}

func critical(client Client, orgs string, adminEndpoint string, region string ) []userInfo {

	var users []userInfo

	targetOrg := map[string] []string {
		"organization_guid": { orgs },
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
				pazmin := strings.Join([]string{adminEndpoint, orgs},"")
				data := userInfo{ Username: dev.Username, Role: "Developer", Admin: pazmin, Region: region}
				users = append(users, data)
			}
		}
		spaceManagers, err := client.ListSpaceManagers(space.Guid)
		if err != nil {
			log.Fatal(err)
		}

		for _, manager := range spaceManagers {
			if validEmail(manager.Username) {
				pazmin := strings.Join([]string{adminEndpoint, orgs},"")
				data := userInfo{ Username: manager.Username, Role: "Space Manager", Admin: pazmin, Region: region}
				users = append(users, data)
			}
		}
		spaceAuditors, err := client.ListSpaceAuditors(space.Guid)
		if err != nil {
			log.Fatal(err)
		}

		for _, auditor := range spaceAuditors {
			if validEmail(auditor.Username) {
				pazmin := strings.Join([]string{adminEndpoint, orgs},"")
				data := userInfo{ Username: auditor.Username, Role: "Space Auditor", Admin: pazmin, Region: region}
				users = append(users, data)
			}
		}
		orgManagers, err := client.ListOrgManagers(orgs)
		if err != nil {
			log.Fatal(err)
		}

		for _, orgManager := range orgManagers {
			if validEmail(orgManager.Username) {
				pazmin := strings.Join([]string{adminEndpoint, orgs},"")
				data := userInfo{ Username: orgManager.Username, Role: "Org Manager", Admin: pazmin, Region: region}
				users = append(users, data)
			}
		}
		orgAuditors, err := client.ListOrgAuditors(orgs)
		if err != nil {
			log.Fatal(err)
		}

		for _, orgAuditor := range orgAuditors {
			if validEmail(orgAuditor.Username) {
				pazmin := strings.Join([]string{adminEndpoint, orgs},"")
				data := userInfo{ Username: orgAuditor.Username, Role: "Org Auditor", Admin: pazmin, Region: region}
				users = append(users, data)
			}
		}
	}

	return users
}

func management(client Client, orgs string, adminEndpoint string, region string) []userInfo {

	var users []userInfo

	orgManagers, err := client.ListOrgManagers(orgs)
	if err != nil {
		log.Fatal(err)
	}

	for _, orgManager := range orgManagers {
		if validEmail(orgManager.Username) {
			pazmin := strings.Join([]string{adminEndpoint, orgs},"")
			data := userInfo{ Username: orgManager.Username, Role: "Org Manager", Admin: pazmin, Region: region}
			users = append(users, data)
		}
	}
	orgAuditors, err := client.ListOrgAuditors(orgs)
	if err != nil {
		log.Fatal(err)
	}

	for _, orgAuditor := range orgAuditors {
		if validEmail(orgAuditor.Username) {
			pazmin := strings.Join([]string{adminEndpoint, orgs},"")
			data := userInfo{ Username: orgAuditor.Username, Role: "Org Auditor", Admin: pazmin, Region: region}
			users = append(users, data)
		}
	}

	orgBillingManagers, err := client.ListOrgBillingManagers(orgs)
	if err != nil {
		log.Fatal(err)
	}

	for _, orgBillingManager := range orgBillingManagers {
		if validEmail(orgBillingManager.Username) {
			pazmin := strings.Join([]string{adminEndpoint, orgs},"")
			data := userInfo{ Username: orgBillingManager.Username, Role: "Billing Manager", Admin: pazmin, Region: region}
			users = append(users, data)
		}
	}
	return users

}
