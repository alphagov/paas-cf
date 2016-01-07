SHELL := /bin/bash
ROOT_PASS_DIR ?= .

all: extract-secrets build-manifest destroy-secrets

build-manifest:
	./build_manifest.sh

extract-secrets:
	PASSWORD_STORE_DIR=~/.paas-pass pass ${ROOT_PASS_DIR}/cloudfoundry/cf-secrets.yml > outputs/cf-secrets.yml

destroy-secrets:
	rm outputs/cf-secrets.yml
