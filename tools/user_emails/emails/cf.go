package emails

import (
	"github.com/cloudfoundry-community/go-cfclient"
	"net/url"
)

// This interface is extracted as a subset of
// methods on the `Client` struct of
// github.com/cloudfoundry-community/go-cfclent.
// We use it so that we can mock the CF client
// calls elsewhere.
type Client interface {
	ListSpaceManagers(spaceGUID string) ([]cfclient.User, error)
	ListSpaceAuditors(spaceGUID string) ([]cfclient.User, error)
	ListSpaceDevelopers(spaceGUID string) ([]cfclient.User, error)
	ListSpacesByQuery(query url.Values) ([]cfclient.Space, error)
	ListOrgs() ([]cfclient.Org, error)
	ListOrgUsers(orgGUID string) ([]cfclient.User, error)
	ListOrgManagers(orgGUID string) ([]cfclient.User, error)
	ListOrgAuditors(orgGUID string) ([]cfclient.User, error)
	ListOrgBillingManagers(orgGUID string) ([]cfclient.User, error)
}
