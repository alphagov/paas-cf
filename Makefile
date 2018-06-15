.PHONY: help test spec lint_yaml lint_terraform lint_shellcheck lint_concourse check-env
.DEFAULT_GOAL := help

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

DEPLOY_ENV_MAX_LENGTH=8
DEPLOY_ENV_VALID_LENGTH=$(shell if [ $$(printf "%s" $(DEPLOY_ENV) | wc -c) -gt $(DEPLOY_ENV_MAX_LENGTH) ]; then echo ""; else echo "OK"; fi)
DEPLOY_ENV_VALID_CHARS=$(shell if echo $(DEPLOY_ENV) | grep -q '^[a-zA-Z0-9-]*$$'; then echo "OK"; else echo ""; fi)

check-env:
	$(if ${DEPLOY_ENV},,$(error Must pass DEPLOY_ENV=<name>))
	$(if ${DEPLOY_ENV_VALID_LENGTH},,$(error Sorry, DEPLOY_ENV ($(DEPLOY_ENV)) has a max length of $(DEPLOY_ENV_MAX_LENGTH), otherwise derived names will be too long))
	$(if ${DEPLOY_ENV_VALID_CHARS},,$(error Sorry, DEPLOY_ENV ($(DEPLOY_ENV)) must use only alphanumeric chars and hyphens, otherwise derived names will be malformatted))
	@./scripts/validate_aws_credentials.sh

test: spec lint_yaml lint_terraform lint_shellcheck lint_concourse lint_ruby lint_posix_newlines ## Run linting tests

spec:
	cd scripts &&\
		go test
	cd scripts &&\
		bundle exec rspec
	cd tools/metrics &&\
		go test -v ./...
	cd concourse/scripts &&\
		go test
	cd concourse/scripts &&\
		bundle exec rspec
	cd manifests/shared &&\
		bundle exec rspec
	cd manifests/cf-manifest &&\
		bundle exec rspec
	cd terraform/scripts &&\
		go test
	cd platform-tests &&\
		./run_tests.sh src/platform/availability/monitor/

lint_yaml:
	find . -name '*.yml' -not -path '*/vendor/*' | xargs yamllint -c yamllint.yml

.PHONY: lint_terraform
lint_terraform: dev ## Lint the terraform files.
	$(eval export TF_VAR_system_dns_zone_name=$SYSTEM_DNS_ZONE_NAME)
	$(eval export TF_VAR_apps_dns_zone_name=$APPS_DNS_ZONE_NAME)
	@terraform/scripts/lint.sh

lint_shellcheck:
	find . -name '*.sh' -not -path '*/vendor/*' -not -path './platform-tests/pkg/*'  -not -path './manifests/cf-deployment/*' | xargs shellcheck

lint_concourse:
	cd .. && SHELLCHECK_OPTS="-e SC1091" python paas-cf/concourse/scripts/pipecleaner.py --fatal-warnings paas-cf/concourse/pipelines/*.yml

.PHONY: lint_ruby
lint_ruby:
	bundle exec govuk-lint-ruby

.PHONY: lint_posix_newlines
lint_posix_newlines:
	git ls-files | grep -v vendor/ | xargs ./scripts/test_posix_newline.sh

GPG = $(shell command -v gpg2 || command -v gpg)

.PHONY: list_merge_keys
list_merge_keys: ## List all GPG keys allowed to sign merge commits.
	$(if $(GPG),,$(error "gpg2 or gpg not found in PATH"))
	@for key in $$(cat .gpg-id); do \
		printf "$${key}: "; \
		if [ "$$($(GPG) --version | awk 'NR==1 { split($$3,version,"."); print version[1]}')" = "2" ]; then \
			$(GPG) --list-keys --with-colons $$key 2> /dev/null | awk -F: '/^uid/ {found = 1; print $$10; exit} END {if (found != 1) {print "*** not found in local keychain ***"}}'; \
		else \
			$(GPG) --list-keys --with-colons $$key 2> /dev/null | awk -F: '/^pub/ {found = 1; print $$10} END {if (found != 1) {print "*** not found in local keychain ***"}}'; \
		fi;\
	done

.PHONY: globals
PASSWORD_STORE_DIR?=${HOME}/.paas-pass
globals:
	$(eval export PASSWORD_STORE_DIR=${PASSWORD_STORE_DIR})
	@true

.PHONY: dev
dev: globals ## Set Environment to DEV
	$(eval export AWS_DEFAULT_REGION ?= eu-west-1)
	$(eval export AWS_ACCOUNT=dev)
	$(eval export MAKEFILE_ENV_TARGET=dev)
	$(eval export PERSISTENT_ENVIRONMENT=false)
	$(eval export ENABLE_DESTROY=true)
	$(eval export ENABLE_AUTODELETE=true)
	$(eval export SYSTEM_DNS_ZONE_NAME=${DEPLOY_ENV}.dev.cloudpipeline.digital)
	$(eval export APPS_DNS_ZONE_NAME=${DEPLOY_ENV}.dev.cloudpipelineapps.digital)
	$(eval export ALERT_EMAIL_ADDRESS=govpaas-alerting-dev@digital.cabinet-office.gov.uk)
	$(eval export SKIP_COMMIT_VERIFICATION=true)
	$(eval export ENV_SPECIFIC_CF_MANIFEST=cf-default.yml)
	$(eval export DISABLE_HEALTHCHECK_DB=true)
	$(eval export ENABLE_DATADOG ?= false)
	$(eval export CONCOURSE_AUTH_DURATION=48h)
	$(eval export DISABLE_PIPELINE_LOCKING=true)
	$(eval export TEST_HEAVY_LOAD=true)
	$(eval export ENABLE_MORNING_DEPLOYMENT=true)
	@true

.PHONY: staging
staging: globals ## Set Environment to Staging
	$(eval export AWS_ACCOUNT=staging)
	$(eval export MAKEFILE_ENV_TARGET=staging)
	$(eval export PERSISTENT_ENVIRONMENT=true)
	$(eval export ENABLE_AUTO_DEPLOY=true)
	$(eval export OUTPUT_TAG_PREFIX=prod-)
	$(eval export SYSTEM_DNS_ZONE_NAME=staging.cloudpipeline.digital)
	$(eval export APPS_DNS_ZONE_NAME=staging.cloudpipelineapps.digital)
	$(eval export ALERT_EMAIL_ADDRESS=the-multi-cloud-paas-team+staging@digital.cabinet-office.gov.uk)
	$(eval export NEW_ACCOUNT_EMAIL_ADDRESS=${ALERT_EMAIL_ADDRESS})
	$(eval export ENV_SPECIFIC_CF_MANIFEST=cf-staging.yml)
	$(eval export ENABLE_DATADOG=true)
	$(eval export DEPLOY_ENV=staging)
	$(eval export TEST_HEAVY_LOAD=true)
	$(eval export COMPOSE_PASSWORD_STORE_HIGH_DIR?=${HOME}/.paas-pass-high)
	$(eval export AWS_DEFAULT_REGION=eu-west-1)
	@true

.PHONY: stg-lon
stg-lon: globals ## Set Environment to stg-lon
	$(eval export AWS_ACCOUNT=staging)
	$(eval export MAKEFILE_ENV_TARGET=stg-lon)
	$(eval export PERSISTENT_ENVIRONMENT=true)
	$(eval export ENABLE_AUTO_DEPLOY=true)
	$(eval export OUTPUT_TAG_PREFIX=prod-lon-)
	$(eval export SYSTEM_DNS_ZONE_NAME=london.staging.cloudpipeline.digital)
	$(eval export APPS_DNS_ZONE_NAME=london.staging.cloudpipelineapps.digital)
	$(eval export ALERT_EMAIL_ADDRESS=the-multi-cloud-paas-team+stg-lon@digital.cabinet-office.gov.uk)
	$(eval export NEW_ACCOUNT_EMAIL_ADDRESS=${ALERT_EMAIL_ADDRESS})
	$(eval export ENV_SPECIFIC_CF_MANIFEST=cf-stg-lon.yml)
	$(eval export ENABLE_DATADOG=true)
	$(eval export DEPLOY_ENV=stg-lon)
	$(eval export TEST_HEAVY_LOAD=true)
	$(eval export COMPOSE_PASSWORD_STORE_HIGH_DIR?=${HOME}/.paas-pass-high)
	$(eval export AWS_DEFAULT_REGION=eu-west-2)
	@true

.PHONY: prod
prod: globals ## Set Environment to Production
	$(eval export AWS_ACCOUNT=prod)
	$(eval export MAKEFILE_ENV_TARGET=prod)
	$(eval export PERSISTENT_ENVIRONMENT=true)
	$(eval export ENABLE_AUTO_DEPLOY=true)
	$(eval export INPUT_TAG_PREFIX=prod-)
	$(eval export SYSTEM_DNS_ZONE_NAME=cloud.service.gov.uk)
	$(eval export APPS_DNS_ZONE_NAME=cloudapps.digital)
	$(eval export ALERT_EMAIL_ADDRESS=the-multi-cloud-paas-team+prod@digital.cabinet-office.gov.uk)
	$(eval export NEW_ACCOUNT_EMAIL_ADDRESS=${ALERT_EMAIL_ADDRESS})
	$(eval export ENV_SPECIFIC_CF_MANIFEST=cf-prod.yml)
	$(eval export DISABLE_CF_ACCEPTANCE_TESTS=true)
	$(eval export ENABLE_DATADOG=true)
	$(eval export DEPLOY_ENV=prod)
	$(eval export COMPOSE_PASSWORD_STORE_HIGH_DIR?=${HOME}/.paas-pass-high)
	$(eval export AWS_DEFAULT_REGION=eu-west-1)
	@true

.PHONY: prod-lon
prod-lon: globals ## Set Environment to prod-lon
	$(eval export AWS_ACCOUNT=prod)
	$(eval export MAKEFILE_ENV_TARGET=prod-lon)
	$(eval export PERSISTENT_ENVIRONMENT=true)
	$(eval export ENABLE_AUTO_DEPLOY=true)
	$(eval export INPUT_TAG_PREFIX=prod-lon-)
	$(eval export SYSTEM_DNS_ZONE_NAME=london.cloud.service.gov.uk)
	$(eval export APPS_DNS_ZONE_NAME=london.cloudapps.digital)
	$(eval export ALERT_EMAIL_ADDRESS=the-multi-cloud-paas-team+prod-lon@digital.cabinet-office.gov.uk)
	$(eval export NEW_ACCOUNT_EMAIL_ADDRESS=${ALERT_EMAIL_ADDRESS})
	$(eval export ENV_SPECIFIC_CF_MANIFEST=cf-prod-lon.yml)
	$(eval export DISABLE_CF_ACCEPTANCE_TESTS=true)
	$(eval export ENABLE_DATADOG=true)
	$(eval export DEPLOY_ENV=prod-lon)
	$(eval export COMPOSE_PASSWORD_STORE_HIGH_DIR?=${HOME}/.paas-pass-high)
	$(eval export AWS_DEFAULT_REGION=eu-west-2)
	@true

.PHONY: bosh-cli
bosh-cli:
	@echo "bosh-cli has moved to paas-bootstrap 🐝"

.PHONY: ssh_bosh
ssh_bosh: ## SSH to the bosh server
	@echo "ssh_bosh has moved to paas-bootstrap 🐝"

.PHONY: pipelines
pipelines: check-env ## Upload pipelines to Concourse
	concourse/scripts/pipelines-cloudfoundry.sh

.PHONY: trigger-deploy
trigger-deploy: check-env ## Trigger a run of the create-cloudfoundry pipeline.
	concourse/scripts/trigger-deploy.sh

.PHONY: showenv
showenv: check-env ## Display environment information
	$(eval export TARGET_CONCOURSE=deployer)
	@concourse/scripts/environment.sh
	@scripts/show-cf-secrets.sh kibana_admin_password uaa_admin_password
	@echo export CONCOURSE_IP=$$(aws ec2 describe-instances \
		--filters 'Name=tag:Name,Values=concourse/*' "Name=key-name,Values=${DEPLOY_ENV}_concourse_key_pair" \
		--query 'Reservations[].Instances[].PublicIpAddress' --output text)

.PHONY: upload-datadog-secrets
upload-datadog-secrets: check-env ## Decrypt and upload Datadog credentials to S3
	$(eval export DATADOG_PASSWORD_STORE_DIR?=${HOME}/.paas-pass)
	$(if ${MAKEFILE_ENV_TARGET},,$(error Must set MAKEFILE_ENV_TARGET))
	$(if ${DATADOG_PASSWORD_STORE_DIR},,$(error Must pass DATADOG_PASSWORD_STORE_DIR=<path_to_password_store>))
	$(if $(wildcard ${DATADOG_PASSWORD_STORE_DIR}),,$(error Password store ${DATADOG_PASSWORD_STORE_DIR} does not exist))
	@scripts/upload-datadog-secrets.sh

.PHONY: upload-compose-secrets
upload-compose-secrets: check-env ## Decrypt and upload Compose credentials to S3
	$(eval export COMPOSE_PASSWORD_STORE_DIR?=${HOME}/.paas-pass)
	$(if ${MAKEFILE_ENV_TARGET},,$(error Must set MAKEFILE_ENV_TARGET))
	$(if ${COMPOSE_PASSWORD_STORE_DIR},,$(error Must pass COMPOSE_PASSWORD_STORE_DIR=<path_to_password_store>))
	$(if $(wildcard ${COMPOSE_PASSWORD_STORE_DIR}),,$(error Password store ${COMPOSE_PASSWORD_STORE_DIR} does not exist))
	@scripts/upload-compose-secrets.sh

.PHONY: upload-google-oauth-secrets
upload-google-oauth-secrets: check-env ## Decrypt and upload Google Admin Console credentials to S3
	$(eval export OAUTH_PASSWORD_STORE_DIR?=${HOME}/.paas-pass)
	$(if ${MAKEFILE_ENV_TARGET},,$(error Must set MAKEFILE_ENV_TARGET))
	$(if ${OAUTH_PASSWORD_STORE_DIR},,$(error Must pass OAUTH_PASSWORD_STORE_DIR=<path_to_password_store>))
	$(if $(wildcard ${OAUTH_PASSWORD_STORE_DIR}),,$(error Password store ${OAUTH_PASSWORD_STORE_DIR} does not exist))
	@scripts/upload-google-oauth-secrets.sh

.PHONY: upload-notify-secrets
upload-notify-secrets: check-env ## Decrypt and upload Notify Credentials to S3
	$(eval export NOTIFY_PASSWORD_STORE_DIR?=${HOME}/.paas-pass)
	$(if ${MAKEFILE_ENV_TARGET},,$(error Must set MAKEFILE_ENV_TARGET))
	$(if ${NOTIFY_PASSWORD_STORE_DIR},,$(error Must pass NOTIFY_PASSWORD_STORE_DIR=<path_to_password_store>))
	$(if $(wildcard ${NOTIFY_PASSWORD_STORE_DIR}),,$(error Password store ${NOTIFY_PASSWORD_STORE_DIR} does not exist))
	@scripts/upload-notify-secrets.sh

.PHONY: pingdom
pingdom: check-env ## Use custom Terraform provider to set up Pingdom check
	$(if ${ACTION},,$(error Must pass ACTION=<plan|apply|...>))
	$(eval export PASSWORD_STORE_DIR=${PASSWORD_STORE_DIR})
	@terraform/scripts/set-up-pingdom.sh ${ACTION}

merge_pr: ## Merge a PR. Must specify number in a PR=<number> form.
	$(if ${PR},,$(error Must pass PR=<number>))
	bundle exec github_merge_sign --pr ${PR}

find_diverged_forks: ## Check all github forks belonging to paas to see if they've diverged upstream
	$(if ${GITHUB_TOKEN},,$(error Must pass GITHUB_TOKEN=<personal github token>))
	./scripts/find_diverged_forks.py alphagov --prefix=paas --github-token=${GITHUB_TOKEN}

.PHONY: run_job
run_job: check-env ## Unbind paas-cf of $JOB in create-cloudfoundry pipeline and then trigger it
	$(if ${JOB},,$(error Must pass JOB=<name>))
	./concourse/scripts/run_job.sh ${JOB}

ssh_concourse: check-env ## SSH to the concourse server. Set SSH_CMD to pass a command to execute.
	@echo "ssh_concourse has moved to paas-bootstrap 🐝"

tunnel: check-env ## SSH tunnel to internal IPs
	@echo "tunnel has moved to paas-bootstrap 🐝"

stop-tunnel: check-env ## Stop SSH tunnel
	@echo "stop-tunnel has moved to paas-bootstrap 🐝"
