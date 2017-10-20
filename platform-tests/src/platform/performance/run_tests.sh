#!/bin/sh

set -eu

godep restore

go test
