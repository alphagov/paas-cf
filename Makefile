.PHONY: help test spec lint_yaml lint_terraform lint_shellcheck lint_concourse check-env
.DEFAULT_GOAL := help

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

DEPLOY_ENV_MAX_LENGTH=8
DEPLOY_ENV_VALID_LENGTH=$(shell if [ $$(printf "%s" $(DEPLOY_ENV) | wc -c) -gt $(DEPLOY_ENV_MAX_LENGTH) ]; then echo ""; else echo "OK"; fi)
DEPLOY_ENV_VALID_CHARS=$(shell if echo $(DEPLOY_ENV) | grep -q '^[a-zA-Z0-9-]*$$'; then echo "OK"; else echo ""; fi)

LOGSEARCH_BOSHRELEASE_TAG=v209.0.0
LOGSEARCH_FOR_CLOUDFOUNDRY_TAG=v207.0.0

check-env:
	$(if ${DEPLOY_ENV},,$(error Must pass DEPLOY_ENV=<name>))
	$(if ${DEPLOY_ENV_VALID_LENGTH},,$(error Sorry, DEPLOY_ENV ($(DEPLOY_ENV)) has a max length of $(DEPLOY_ENV_MAX_LENGTH), otherwise derived names will be too long))
	$(if ${DEPLOY_ENV_VALID_CHARS},,$(error Sorry, DEPLOY_ENV ($(DEPLOY_ENV)) must use only alphanumeric chars and hyphens, otherwise derived names will be malformatted))
	$(if ${MAKEFILE_ENV_TARGET},,$(error Must set MAKEFILE_ENV_TARGET))
	$(if $(wildcard ${PAAS_PASSWORD_STORE_DIR}),,$(error Password store ${PAAS_PASSWORD_STORE_DIR} (PAAS_PASSWORD_STORE_DIR) does not exist))
	$(if $(wildcard ${PAAS_HIGH_PASSWORD_STORE_DIR}),,$(error Password store ${PAAS_HIGH_PASSWORD_STORE_DIR} (PAAS_HIGH_PASSWORD_STORE_DIR) does not exist))
	@./scripts/validate_aws_credentials.sh

test: spec compile_platform_tests lint_yaml lint_terraform lint_shellcheck lint_concourse lint_ruby lint_posix_newlines lint_symlinks ## Run linting tests

scripts_spec:
	cd scripts &&\
		go get -d -t . &&\
		go test
	cd scripts &&\
		bundle exec rspec

tools_spec:
	cd tools/metrics &&\
		go test -v $(go list ./... | grep -v acceptance)
	cd tools/user_emails &&\
		go test -v ./...

concourse_spec:
	cd concourse &&\
		bundle exec rspec
	cd concourse/scripts &&\
		go get -d -t . &&\
		go test
	cd concourse/scripts &&\
		bundle exec rspec

shared_manifests_spec:
	cd manifests/shared &&\
		bundle exec rspec
	cd manifests/cloud-config &&\
		bundle exec rspec

cf_manifest_spec:
	cd manifests/cf-manifest &&\
		bundle exec rspec

prometheus_manifest_spec:
	cd manifests/prometheus &&\
		bundle exec rspec

manifests_spec: shared_manifests_spec cf_manifest_spec prometheus_manifest_spec

terraform_spec:
	cd terraform/scripts &&\
		go get -d -t . &&\
		go test
	cd terraform &&\
		bundle exec rspec

platform_tests_spec:
	cd platform-tests &&\
		./run_tests.sh src/platform/availability/monitor/

spec: scripts_spec tools_spec concourse_spec manifests_spec terraform_spec platform_tests_spec

compile_platform_tests:
	GOPATH="$$(pwd)/platform-tests" \
	go test -run ^$$ \
		platform/acceptance \
		platform/availability/api \
		platform/availability/app \
		platform/availability/helpers \
		platform/availability/monitor

lint_yaml:
	find . -name '*.yml' -not -path '*/vendor/*' -not -path './manifests/prometheus/upstream/*' -not -path './manifests/cf-deployment/ci/template/*' | xargs yamllint -c yamllint.yml

.PHONY: lint_terraform
lint_terraform: dev ## Lint the terraform files.
	$(eval export TF_VAR_system_dns_zone_name=$SYSTEM_DNS_ZONE_NAME)
	$(eval export TF_VAR_apps_dns_zone_name=$APPS_DNS_ZONE_NAME)
	@terraform/scripts/lint.sh

lint_shellcheck:
	find . -name '*.sh' -not -path '*/vendor/*' -not -path './platform-tests/pkg/*'  -not -path './manifests/cf-deployment/*' -not -path './manifests/prometheus/upstream/*' | xargs shellcheck

lint_concourse:
	cd .. && SHELLCHECK_OPTS="-e SC1091" python paas-cf/concourse/scripts/pipecleaner.py --fatal-warnings paas-cf/concourse/pipelines/*.yml

.PHONY: lint_ruby
lint_ruby:
	bundle exec govuk-lint-ruby

.PHONY: lint_posix_newlines
lint_posix_newlines:
	@# for some reason `git ls-files` is including 'manifests/cf-deployment' in its output...which is a directory
	git ls-files | grep -v -e vendor/ -e manifests/cf-deployment -e manifests/prometheus/upstream | xargs ./scripts/test_posix_newline.sh

.PHONY: lint_symlinks
lint_symlinks:
	# This mini-test tests that our script correctly identifies hanging symlinks
	@rm -f "$$TMPDIR/test-lint_symlinks"
	@ln -s /this/does/not/exist "$$TMPDIR/test-lint_symlinks"
	! echo "$$TMPDIR/test-lint_symlinks" | ./scripts/test_symlinks.sh 2>/dev/null # If <<this<< errors, the script is broken
	@rm "$$TMPDIR/test-lint_symlinks"
	# Successful end of mini-test
	find . -type l -not -path '*/vendor/*' \
	| grep -v $$(git submodule foreach 'echo -e ^./$$path' --quiet) \
	| ./scripts/test_symlinks.sh

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

.PHONY: update_merge_keys
update_merge_keys:
	ruby concourse/scripts/generate-public-key-vars.rb

.PHONY: dev
dev: ## Set Environment to DEV
	$(eval export AWS_DEFAULT_REGION ?= eu-west-1)
	$(eval export AWS_ACCOUNT=dev)
	$(eval export MAKEFILE_ENV_TARGET=dev)
	$(eval export PERSISTENT_ENVIRONMENT=false)
	$(eval export ENABLE_DESTROY=true)
	$(eval export ENABLE_AUTODELETE=true)
	$(eval export SYSTEM_DNS_ZONE_NAME=${DEPLOY_ENV}.dev.cloudpipeline.digital)
	$(eval export APPS_DNS_ZONE_NAME=${DEPLOY_ENV}.dev.cloudpipelineapps.digital)
	$(eval export ALERT_EMAIL_ADDRESS?=govpaas-alerting-dev@digital.cabinet-office.gov.uk)
	$(eval export NEW_ACCOUNT_EMAIL_ADDRESS?=the-multi-cloud-paas-team+dev@digital.cabinet-office.gov.uk)
	$(eval export ENABLE_ALERT_NOTIFICATIONS ?= false)
	$(eval export SKIP_COMMIT_VERIFICATION=true)
	$(eval export ENV_SPECIFIC_BOSH_VARS_FILE=default.yml)
	$(eval export DISABLE_HEALTHCHECK_DB=true)
	$(eval export CONCOURSE_AUTH_DURATION=48h)
	$(eval export DISABLE_PIPELINE_LOCKING=true)
	$(eval export TEST_HEAVY_LOAD=true)
	$(eval export PAAS_PASSWORD_STORE_DIR?=${HOME}/.paas-pass)
	$(eval export PAAS_HIGH_PASSWORD_STORE_DIR?=${HOME}/.paas-pass)
	$(eval export ENABLE_MORNING_DEPLOYMENT=true)
	$(eval export SLIM_DEV_DEPLOYMENT ?= true)
	@true

.PHONY: stg-lon
stg-lon: ## Set Environment to stg-lon
	$(eval export AWS_ACCOUNT=staging)
	$(eval export MAKEFILE_ENV_TARGET=stg-lon)
	$(eval export PERSISTENT_ENVIRONMENT=true)
	$(eval export ENABLE_AUTO_DEPLOY=true)
	$(eval export OUTPUT_TAG_PREFIX=prod-)
	$(eval export SYSTEM_DNS_ZONE_NAME=london.staging.cloudpipeline.digital)
	$(eval export APPS_DNS_ZONE_NAME=london.staging.cloudpipelineapps.digital)
	$(eval export ALERT_EMAIL_ADDRESS=the-multi-cloud-paas-team+stg-lon@digital.cabinet-office.gov.uk)
	$(eval export NEW_ACCOUNT_EMAIL_ADDRESS=${ALERT_EMAIL_ADDRESS})
	$(eval export ENV_SPECIFIC_BOSH_VARS_FILE=stg-lon.yml)
	$(eval export DEPLOY_ENV=stg-lon)
	$(eval export TEST_HEAVY_LOAD=true)
	$(eval export PAAS_PASSWORD_STORE_DIR?=${HOME}/.paas-pass)
	$(eval export PAAS_HIGH_PASSWORD_STORE_DIR?=${HOME}/.paas-pass-high)
	$(eval export AWS_DEFAULT_REGION=eu-west-2)
	@true

.PHONY: prod
prod: ## Set Environment to Production
	$(eval export AWS_ACCOUNT=prod)
	$(eval export MAKEFILE_ENV_TARGET=prod)
	$(eval export PERSISTENT_ENVIRONMENT=true)
	$(eval export ENABLE_AUTO_DEPLOY=true)
	$(eval export INPUT_TAG_PREFIX=prod-)
	$(eval export SYSTEM_DNS_ZONE_NAME=cloud.service.gov.uk)
	$(eval export APPS_DNS_ZONE_NAME=cloudapps.digital)
	$(eval export ALERT_EMAIL_ADDRESS=the-multi-cloud-paas-team+prod@digital.cabinet-office.gov.uk)
	$(eval export NEW_ACCOUNT_EMAIL_ADDRESS=${ALERT_EMAIL_ADDRESS})
	$(eval export ENV_SPECIFIC_BOSH_VARS_FILE=prod.yml)
	$(eval export DISABLE_CF_ACCEPTANCE_TESTS=true)
	$(eval export DEPLOY_ENV=prod)
	$(eval export PAAS_PASSWORD_STORE_DIR?=${HOME}/.paas-pass)
	$(eval export PAAS_HIGH_PASSWORD_STORE_DIR?=${HOME}/.paas-pass-high)
	$(eval export AWS_DEFAULT_REGION=eu-west-1)
	@true

.PHONY: prod-lon
prod-lon: ## Set Environment to prod-lon
	$(eval export AWS_ACCOUNT=prod)
	$(eval export MAKEFILE_ENV_TARGET=prod-lon)
	$(eval export PERSISTENT_ENVIRONMENT=true)
	$(eval export ENABLE_AUTO_DEPLOY=true)
	$(eval export INPUT_TAG_PREFIX=prod-)
	$(eval export SYSTEM_DNS_ZONE_NAME=london.cloud.service.gov.uk)
	$(eval export APPS_DNS_ZONE_NAME=london.cloudapps.digital)
	$(eval export ALERT_EMAIL_ADDRESS=the-multi-cloud-paas-team+prod-lon@digital.cabinet-office.gov.uk)
	$(eval export NEW_ACCOUNT_EMAIL_ADDRESS=${ALERT_EMAIL_ADDRESS})
	$(eval export ENV_SPECIFIC_BOSH_VARS_FILE=prod-lon.yml)
	$(eval export DISABLE_CF_ACCEPTANCE_TESTS=true)
	$(eval export DEPLOY_ENV=prod-lon)
	$(eval export PAAS_PASSWORD_STORE_DIR?=${HOME}/.paas-pass)
	$(eval export PAAS_HIGH_PASSWORD_STORE_DIR?=${HOME}/.paas-pass-high)
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

# This target matches any "monitor-" prefix; the "$(*)" magic variable
# contains the wildcard suffix (not the entire target name).
monitor-%: export MONITORED_DEPLOY_ENV=$(*)
monitor-%: export MONITORED_STATE_BUCKET=gds-paas-$(*)-state
monitor-%: export PIPELINES_TO_UPDATE=monitor-$(*)
monitor-%: check-env ## Upload an optional, cross-region monitoring pipeline to Concourse
	MONITORED_AWS_REGION=$$(aws s3api get-bucket-location --bucket $$MONITORED_STATE_BUCKET --output text --query LocationConstraint) \
		concourse/scripts/pipelines-cloudfoundry.sh

.PHONY: trigger-deploy
trigger-deploy: check-env ## Trigger a run of the create-cloudfoundry pipeline.
	concourse/scripts/trigger-deploy.sh

.PHONY: pause-kick-off
pause-kick-off: check-env ## Pause the morning kick-off of deployment.
	concourse/scripts/pause-kick-off.sh pin

.PHONY: unpause-kick-off
unpause-kick-off: check-env ## Unpause the morning kick-off of deployment.
	concourse/scripts/pause-kick-off.sh unpin

.PHONY: showenv
showenv: check-env ## Display environment information
	$(eval export TARGET_CONCOURSE=deployer)
	@concourse/scripts/environment.sh
	@scripts/show-vars-store-secrets.sh cf-vars-store cf_admin_password uaa_admin_client_secret
	@echo export CONCOURSE_IP=$$(aws ec2 describe-instances \
		--filters "Name=tag:deploy_env,Values=${DEPLOY_ENV}" 'Name=tag:instance_group,Values=concourse' \
		--query 'Reservations[].Instances[].PublicIpAddress' --output text)
	@scripts/show-vars-store-secrets.sh prometheus-vars-store alertmanager_password grafana_password grafana_mon_password prometheus_password

.PHONY: upload-all-secrets
upload-all-secrets: upload-google-oauth-secrets upload-microsoft-oauth-secrets upload-notify-secrets upload-aiven-secrets upload-logit-secrets upload-pagerduty-secrets

.PHONY: upload-google-oauth-secrets
upload-google-oauth-secrets: check-env ## Decrypt and upload Google Admin Console credentials to S3
	$(eval export PASSWORD_STORE_DIR=${PAAS_PASSWORD_STORE_DIR})
	@scripts/upload-google-oauth-secrets.rb

.PHONY: upload-microsoft-oauth-secrets
upload-microsoft-oauth-secrets: check-env ## Decrypt and upload Microsoft Identity credentials to S3
	$(eval export PASSWORD_STORE_DIR=${PAAS_PASSWORD_STORE_DIR})
	@scripts/upload-microsoft-oauth-secrets.rb

.PHONY: upload-notify-secrets
upload-notify-secrets: check-env ## Decrypt and upload Notify Credentials to S3
	$(eval export PASSWORD_STORE_DIR=${PAAS_PASSWORD_STORE_DIR})
	@scripts/upload-notify-secrets.rb

.PHONY: upload-aiven-secrets
upload-aiven-secrets: check-env ## Decrypt and upload Aiven credentials to S3
	$(eval export PASSWORD_STORE_DIR=${PAAS_HIGH_PASSWORD_STORE_DIR})
	@scripts/upload-aiven-secrets.rb

.PHONY: upload-logit-secrets
upload-logit-secrets: check-env ## Decrypt and upload Logit credentials to S3
	$(eval export PASSWORD_STORE_DIR=${PAAS_PASSWORD_STORE_DIR})
	@scripts/upload-logit-secrets.rb

.PHONY: upload-pagerduty-secrets
upload-pagerduty-secrets: check-env ## Decrypt and upload pagerduty credentials to S3
	$(eval export PASSWORD_STORE_DIR=${PAAS_PASSWORD_STORE_DIR})
	@scripts/upload-pagerduty-secrets.rb

.PHONY: pingdom
pingdom: check-env ## Use custom Terraform provider to set up Pingdom check
	$(if ${ACTION},,$(error Must pass ACTION=<plan|apply|...>))
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

.PHONY: logit-filters
logit-filters:
	mkdir -p config/logit/output
	docker run --rm -it \
		-v $(CURDIR):/mnt:ro \
		-v $(CURDIR)/config/logit/output:/output:rw \
		-w /mnt \
		jruby:9.1-alpine ./scripts/generate_logit_filters.sh $(LOGSEARCH_BOSHRELEASE_TAG) $(LOGSEARCH_FOR_CLOUDFOUNDRY_TAG)
	@echo "updated $(CURDIR)/config/logit/output/generated_logit_filters.conf"

.PHONY: show-tenant-comms-addresses
show-tenant-comms-addresses:
	$(eval export API_TOKEN=`cf oauth-token | cut -f 2 -d ' '`)
	$(eval export API_ENDPOINT=https://api.${SYSTEM_DNS_ZONE_NAME})
	@cd tools/user_emails/ && go build && API_TOKEN=$(API_TOKEN) ./user_emails

clean-up-s3-secrets:
	@scripts/clean_up_s3_secrets.sh
