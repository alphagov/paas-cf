.PHONY: help test spec lint_yaml lint_terraform lint_shellcheck lint_concourse check-env
.DEFAULT_GOAL := help

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

DEPLOY_ENV_MAX_LENGTH=12
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
		BUNDLE_GEMFILE=Gemfile bundle exec rspec
	cd tools/metrics &&\
		go test
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
	find . -name '*.sh' -not -path '*/vendor/*' -not -path './platform-tests/pkg/*' | xargs shellcheck

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
	$(eval export AWS_DEFAULT_REGION=eu-west-1)
	$(eval export PASSWORD_STORE_DIR=${PASSWORD_STORE_DIR})
	@true

.PHONY: dev
dev: globals ## Set Environment to DEV
	$(eval export AWS_ACCOUNT=dev)
	$(eval export ENABLE_METRICS ?= false)
	$(eval export ENABLE_USAGE_EVENTS_COLLECTION ?= false)
	$(eval export CF_SKIP_SSL_VALIDATION=true)
	$(eval export ENABLE_DESTROY=true)
	$(eval export ENABLE_AUTODELETE=true)
	$(eval export SYSTEM_DNS_ZONE_NAME=${DEPLOY_ENV}.dev.cloudpipeline.digital)
	$(eval export APPS_DNS_ZONE_NAME=${DEPLOY_ENV}.dev.cloudpipelineapps.digital)
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
	$(eval export ENABLE_METRICS=false)
	$(eval export ENABLE_USAGE_EVENTS_COLLECTION=false)
	$(eval export ENABLE_AUTO_DEPLOY=true)
	$(eval export SKIP_UPLOAD_GENERATED_CERTS=true)
	$(eval export TAG_PREFIX=prod-)
	$(eval export SYSTEM_DNS_ZONE_NAME=staging.cloudpipeline.digital)
	$(eval export APPS_DNS_ZONE_NAME=staging.cloudpipelineapps.digital)
	$(eval export ALERT_EMAIL_ADDRESS=the-multi-cloud-paas-team+staging@digital.cabinet-office.gov.uk)
	$(eval export NEW_ACCOUNT_EMAIL_ADDRESS=${ALERT_EMAIL_ADDRESS})
	$(eval export ENV_SPECIFIC_CF_MANIFEST=cf-staging.yml)
	$(eval export ENABLE_DATADOG=true)
	$(eval export DEPLOY_ENV=staging)
	$(eval export TEST_HEAVY_LOAD=true)
	$(eval export COMPOSE_PASSWORD_STORE_HIGH_DIR?=${HOME}/.paas-pass-high)
	@true

.PHONY: prod
prod: globals ## Set Environment to Production
	$(eval export AWS_ACCOUNT=prod)
	$(eval export ENABLE_METRICS=true)
	$(eval export ENABLE_USAGE_EVENTS_COLLECTION=true)
	$(eval export ENABLE_AUTO_DEPLOY=true)
	$(eval export SKIP_UPLOAD_GENERATED_CERTS=true)
	$(eval export PAAS_CF_TAG_FILTER=prod-*)
	$(eval export SYSTEM_DNS_ZONE_NAME=cloud.service.gov.uk)
	$(eval export APPS_DNS_ZONE_NAME=cloudapps.digital)
	$(eval export ALERT_EMAIL_ADDRESS=the-multi-cloud-paas-team+prod@digital.cabinet-office.gov.uk)
	$(eval export NEW_ACCOUNT_EMAIL_ADDRESS=${ALERT_EMAIL_ADDRESS})
	$(eval export ENV_SPECIFIC_CF_MANIFEST=cf-prod.yml)
	$(eval export DISABLE_CF_ACCEPTANCE_TESTS=true)
	$(eval export ENABLE_DATADOG=true)
	$(eval export ENABLE_PAAS_DASHBOARD=true)
	$(eval export DEPLOY_RUBBERNECKER=true)
	$(eval export DEPLOY_ENV=prod)
	$(eval export COMPOSE_PASSWORD_STORE_HIGH_DIR?=${HOME}/.paas-pass-high)
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
	@scripts/show-cf-secrets.sh grafana_admin_password kibana_admin_password uaa_admin_password
	@echo export CONCOURSE_IP=$$(aws ec2 describe-instances \
		--filters 'Name=tag:Name,Values=concourse/*' "Name=key-name,Values=${DEPLOY_ENV}_concourse_key_pair" \
		--query 'Reservations[].Instances[].PublicIpAddress' --output text)

.PHONY: upload-datadog-secrets
upload-datadog-secrets: check-env ## Decrypt and upload Datadog credentials to S3
	$(eval export DATADOG_PASSWORD_STORE_DIR?=${HOME}/.paas-pass)
	$(if ${AWS_ACCOUNT},,$(error Must set environment to staging/prod))
	$(if ${DATADOG_PASSWORD_STORE_DIR},,$(error Must pass DATADOG_PASSWORD_STORE_DIR=<path_to_password_store>))
	$(if $(wildcard ${DATADOG_PASSWORD_STORE_DIR}),,$(error Password store ${DATADOG_PASSWORD_STORE_DIR} does not exist))
	@scripts/upload-datadog-secrets.sh

.PHONY: upload-compose-secrets
upload-compose-secrets: check-env ## Decrypt and upload Compose credentials to S3
	$(eval export COMPOSE_PASSWORD_STORE_DIR?=${HOME}/.paas-pass)
	$(if ${AWS_ACCOUNT},,$(error Must set environment to dev/staging/prod))
	$(if ${COMPOSE_PASSWORD_STORE_DIR},,$(error Must pass COMPOSE_PASSWORD_STORE_DIR=<path_to_password_store>))
	$(if $(wildcard ${COMPOSE_PASSWORD_STORE_DIR}),,$(error Password store ${COMPOSE_PASSWORD_STORE_DIR} does not exist))
	@scripts/upload-compose-secrets.sh

.PHONY: upload-google-oauth-secrets
upload-google-oauth-secrets: check-env ## Decrypt and upload Google Admin Console credentials to S3
	$(eval export OAUTH_PASSWORD_STORE_DIR?=${HOME}/.paas-pass)
	# FIXME After it has been tested, we'd like to restrict its usage in dev.
	# $(if ${AWS_ACCOUNT},,$(error Must set environment to staging/prod))
	$(if ${OAUTH_PASSWORD_STORE_DIR},,$(error Must pass OAUTH_PASSWORD_STORE_DIR=<path_to_password_store>))
	$(if $(wildcard ${OAUTH_PASSWORD_STORE_DIR}),,$(error Password store ${OAUTH_PASSWORD_STORE_DIR} does not exist))
	@scripts/upload-google-oauth-secrets.sh

upload-tracker-token: check-env ## Decrypt and upload Pivotal tracker API token to S3
	pass pivotal/tracker_token | aws s3 cp - "s3://gds-paas-${DEPLOY_ENV}-state/tracker_token"

upload-pagerduty-token: check-env ## Decrypt and upload Pagerduty API token to S3
	pass pagerduty/rubbernecker_api_token | aws s3 cp - "s3://gds-paas-${DEPLOY_ENV}-state/pagerduty_api_token"

.PHONY: manually_upload_certs
CERT_PASSWORD_STORE_DIR?=~/.paas-pass-high
manually_upload_certs: check-env ## Manually upload to AWS the SSL certificates for public facing endpoints
	$(if ${ACTION},,$(error Must pass ACTION=<plan|apply|...>))
	# check password store and if varables are accesible
	$(if ${CERT_PASSWORD_STORE_DIR},,$(error Must pass CERT_PASSWORD_STORE_DIR=<path_to_password_store>))
	$(if $(wildcard ${CERT_PASSWORD_STORE_DIR}),,$(error Password store ${CERT_PASSWORD_STORE_DIR} does not exist))
	@terraform/scripts/manually-upload-certs.sh ${ACTION}

.PHONY: pingdom
pingdom: check-env ## Use custom Terraform provider to set up Pingdom check
	$(if ${ACTION},,$(error Must pass ACTION=<plan|apply|...>))
	$(eval export PASSWORD_STORE_DIR=${PASSWORD_STORE_DIR})
	@terraform/scripts/set-up-pingdom.sh ${ACTION}

.PHONY: setup_cdn_instances
setup_cdn_instances: check-env ## Setup the CloudFront Distribution instances, by reading their config from terraform/cloudfront/instances.tf.
	$(if ${ACTION},,$(error Must pass ACTION=<plan|apply|...>))
	@terraform/scripts/set-up-cdn-instances.sh ${ACTION}

merge_pr: ## Merge a PR. Must specify number in a PR=<number> form.
	$(if ${PR},,$(error Must pass PR=<number>))
	bundle exec github_merge_sign --pr ${PR}

find_diverged_forks: ## Check all github forks belonging to paas to see if they've diverged upstream
	$(if ${GITHUB_TOKEN},,$(error Must pass GITHUB_TOKEN=<personal github token>))
	./scripts/find_diverged_forks.py alphagov --prefix=paas --extra-repo=cf-release --extra-repo=graphite-nozzle --github-token=${GITHUB_TOKEN}

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

show-cf-memory-usage: ## Show the memory usage of the current CF cluster
	$(eval export API_ENDPOINT=https://api.${SYSTEM_DNS_ZONE_NAME})
	@./scripts/show-cf-memory-usage.rb
