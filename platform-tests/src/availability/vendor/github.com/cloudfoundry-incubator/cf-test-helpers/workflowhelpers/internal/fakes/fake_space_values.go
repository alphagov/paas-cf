package fakes

type FakeSpaceValues struct {
	organizationName string
	spaceName        string
}

func NewFakeSpaceValues(orgName, spaceName string) *FakeSpaceValues {
	return &FakeSpaceValues{
		organizationName: orgName,
		spaceName:        spaceName,
	}
}

func (space *FakeSpaceValues) OrganizationName() string {
	return space.organizationName
}
func (space *FakeSpaceValues) SpaceName() string {
	return space.spaceName
}
