# go-cfclient

### Overview

[![Build Status](https://img.shields.io/travis/cloudfoundry-community/go-cfclient.svg)](https://travis-ci.org/cloudfoundry-community/go-cfclient) [![GoDoc](https://img.shields.io/badge/godoc-reference-blue.svg)](https://godoc.org/github.com/cloudfoundry-community/go-cfclient)

`cfclient` is a package to assist you in writing apps that need information out of [Cloud Foundry](http://cloudfoundry.org). It provides functions and structures to retrieve


### Usage

```
go get github.com/cloudfoundry-community/go-cfclient
```

Some example code:

```go
package main

import (
	"github.com/cloudfoundry-community/go-cfclient"
)

func main() {
  c := &cfclient.Config{
    ApiAddress:   "https://api.10.244.0.34.xip.io",
    Username:     "admin",
    Password:     "admin",
  }
  client, _ := cfclient.NewClient(c)
  apps, _ := client.ListApps()
  fmt.Println(apps)
}
```

### Developing & Contributing

You can use Godep to restore the dependency
Tested with go1.5.3
```bash
godep go build
```

Pull requests welcome.
