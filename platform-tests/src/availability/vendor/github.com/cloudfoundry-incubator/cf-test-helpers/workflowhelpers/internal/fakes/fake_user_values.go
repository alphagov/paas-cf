package fakes

type FakeUserValues struct {
	username string
	password string
}

func NewFakeUserValues(username, password string) *FakeUserValues {
	return &FakeUserValues{
		username: username,
		password: password,
	}
}

func (user *FakeUserValues) Username() string {
	return user.username
}

func (user *FakeUserValues) Password() string {
	return user.password
}
