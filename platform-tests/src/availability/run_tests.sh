#!/bin/sh

set -eu

go test -timeout 130m -ginkgo.v

