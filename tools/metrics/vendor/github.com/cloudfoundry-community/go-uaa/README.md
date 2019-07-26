# `go-uaa` [![Travis-CI](https://travis-ci.org/cloudfoundry-community/go-uaa.svg)](https://travis-ci.org/cloudfoundry-community/go-uaa) [![godoc](https://godoc.org/github.com/cloudfoundry-community/go-uaa?status.svg)](http://godoc.org/github.com/cloudfoundry-community/go-uaa) [![Report card](https://goreportcard.com/badge/github.com/cloudfoundry-community/go-uaa)](https://goreportcard.com/report/github.com/cloudfoundry-community/go-uaa)

### Overview

`go-uaa` is a client library for the [UAA API](https://docs.cloudfoundry.org/api/uaa/). It is a [`go module`](https://github.com/golang/go/wiki/Modules).

### Usage

#### Step 1: Add `go-uaa` As A Dependency
```
$ go mod init # optional
$ go get -u github.com/cloudfoundry-community/go-uaa
$ cat go.mod
```

```
module github.com/cloudfoundry-community/go-uaa/cmd/test

go 1.12

require github.com/cloudfoundry-community/go-uaa latest
```

#### Step 2: Construct and Use `uaa.API`

```bash
$ cat main.go
```

```go
package main

import (
	"log"

	uaa "github.com/cloudfoundry-community/go-uaa"
)

func main() {
	// construct the API, and validate it
	api := uaa.New("https://uaa.example.net", "").WithClientCredentials("client-id", "client-secret", uaa.JSONWebToken)
	err := api.Validate()
	if err != nil {
		log.Fatal(err)
	}

	// use the API to fetch a user
	user, err := api.GetUserByUsername("test@example.net", "uaa", "")
	if err != nil {
		log.Fatal(err)
	}
	log.Printf("Hello, %s\n", user.Name.GivenName)
}
```

### Experimental

* For the foreseeable future, releases will be in the `v0.x.y` range
* You should expect breaking changes until `v1.x.y` releases occur
* Notifications of breaking changes will be made via release notes associated with each tag
* You should [use `go modules`](https://blog.golang.org/using-go-modules) with this package

### Contributing

Pull requests welcome.
