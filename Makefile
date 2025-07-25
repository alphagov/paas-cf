.DEFAULT_GOAL := help

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

DEPLOY_ENV_MAX_LENGTH=8
DEPLOY_ENV_VALID_LENGTH=$(shell if [ $$(printf "%s" $(DEPLOY_ENV) | wc -c) -gt $(DEPLOY_ENV_MAX_LENGTH) ]; then echo ""; else echo "OK"; fi)
DEPLOY_ENV_VALID_CHARS=$(shell if echo $(DEPLOY_ENV) | grep -q '^[a-zA-Z0-9-]*$$'; then echo "OK"; else echo ""; fi)

LOGSEARCH_BOSHRELEASE_TAG=v211.1.0
LOGSEARCH_FOR_CLOUDFOUNDRY_TAG=8be9abc6c8e50b0e83f80cbd8610baff7a9ee1e3

GPG_KEYSERVER := hkps://keys.openpgp.org

.PHONY: check-env
check-env:
	$(if ${DEPLOY_ENV},,$(error Must pass DEPLOY_ENV=<name>))
	$(if ${DEPLOY_ENV_VALID_LENGTH},,$(error Sorry, DEPLOY_ENV ($(DEPLOY_ENV)) has a max length of $(DEPLOY_ENV_MAX_LENGTH), otherwise derived names will be too long))
	$(if ${DEPLOY_ENV_VALID_CHARS},,$(error Sorry, DEPLOY_ENV ($(DEPLOY_ENV)) must use only alphanumeric chars and hyphens, otherwise derived names will be malformatted))
	$(if ${MAKEFILE_ENV_TARGET},,$(error Must set MAKEFILE_ENV_TARGET))
	@./scripts/validate_aws_credentials.sh

.PHONY: test
test: manifests_spec terraform_spec platform_tests_spec config_spec lint

.PHONY: tools_spec
tools_spec:
	cd tools/metrics &&\
		go test -v $(go list ./... | grep -v acceptance)
	cd tools/user_emails &&\
		go test -v ./...
	cd tools/pipecleaner &&\
		go test -v ./...
	cd tools/user_management &&\
		bundle exec rspec --format documentation
	cd tools/cops &&\
		bundle exec rspec --format documentation

.PHONY: concourse_spec
concourse_spec:
	cd concourse &&\
		bundle exec rspec
	cd concourse/scripts &&\
		go get -t . &&\
		go test
	cd concourse/scripts &&\
		bundle exec rspec

.PHONY: cloud_config_manifests_spec
cloud_config_manifests_spec:
	cd manifests/cloud-config &&\
		bundle exec rspec

.PHONY: runtime_config_manifests_spec
runtime_config_manifests_spec:
	cd manifests/runtime-config &&\
		bundle exec rspec

.PHONY: cf_manifest
cf_manifest: check-env
	@./manifests/cf-manifest/scripts/generate-env-manifest.sh

.PHONY: cf_manifest_spec
cf_manifest_spec:
	cd manifests/cf-manifest &&\
		bundle exec rspec

.PHONY: cf_manifest_stub
cf_manifest_stub:
	@./manifests/cf-manifest/scripts/generate-stub-manifest.sh

.PHONY: prometheus_manifest_spec
prometheus_manifest_spec:
	cd manifests/prometheus &&\
		bundle exec rspec

.PHONY: prometheus_manifest
prometheus_manifest: check-env
	@./manifests/prometheus/scripts/generate-env-manifest.sh

.PHONY: prometheus_manifest_stub
prometheus_manifest_stub:
	@./manifests/prometheus/scripts/generate-stub-manifest.sh

.PHONY: app_autoscaler_manifest
app_autoscaler_manifest: check-env
	@./manifests/app-autoscaler/scripts/generate-env-manifest.sh

.PHONY: app_autoscaler_manifest_spec
app_autoscaler_manifest_spec:
	cd manifests/app-autoscaler &&\
		bundle exec rspec

.PHONY: app_autoscaler_manifest_stub
app_autoscaler_manifest_stub:
	@./manifests/app-autoscaler/scripts/generate-stub-manifest.sh

.PHONY: manifest_spec
manifests_spec: cloud_config_manifests_spec runtime_config_manifests_spec cf_manifest_spec prometheus_manifest_spec app_autoscaler_manifest_spec

.PHONY: lint-terraform
lint-terraform:
	@./scripts/lint-terraform.sh

.PHONY: terraform-fmt
terraform-fmt: ## Run terraform fmt to print out changes that need to be made
	@terraform fmt -write=false -diff -recursive terraform/

.PHONY: terraform-fix
terraform-fix: ## Run terraform fmt to print out and make the changes that need to be made
	@terraform fmt -write=true -diff -recursive terraform/


.PHONY: terraform_spec
terraform_spec:
	cd terraform &&\
		terraform init
	cd terraform/scripts &&\
		go get -t . &&\
		go test
	-wget "https://github.com/tmccombs/hcl2json/releases/download/v0.3.2/hcl2json_$$(go env GOOS)_$$(go env GOARCH)" \
		-q \
		-nc \
		-O "${GOPATH}/bin/hcl2json" # The dash at the start makes it ignore exit codes. `-nc` gives an exit code of 1 if the file already exists
	chmod +x "${GOPATH}/bin/hcl2json";
	cd terraform &&\
		bundle exec rspec

.PHONY: platform_tests_spec
platform_tests_spec:
	cd platform-tests/availability/monitor &&\
		go test

.PHONY: config_spec
config_spec:
	cd config &&\
		bundle exec rspec

.PHONY: compile_platform_tests
compile_platform_tests:
	cd platform-tests &&\
		go vet ./...

.PHONY: lint_yaml
lint_yaml:
	find . -name '*.yml' \
		-not -path '*/vendor/*' \
		-not -path './manifests/prometheus/upstream/*' \
		-not -path './manifests/app-autoscaler/upstream/*' \
		-not -path './manifests/cf-deployment/ci/template/*' \
	| grep -v pipecleaner_invalid.yml \
	| grep -v -- -UPSTREAM.yml \
	| xargs yamllint -c yamllint.yml

.PHONY: lint_terraform
lint_terraform: dev ## Lint the terraform files.
	$(eval export TF_VAR_system_dns_zone_name=$SYSTEM_DNS_ZONE_NAME)
	$(eval export TF_VAR_apps_dns_zone_name=$APPS_DNS_ZONE_NAME)
	@terraform/scripts/lint.sh

.PHONY: lint_shellcheck
lint_shellcheck:
	find . -name '*.sh' \
		-not -path './.git/*' \
		-not -path '*/vendor/*' \
		-not -path './platform-tests/pkg/*'  \
		-not -path './manifests/cf-deployment/*' \
		-not -path './manifests/prometheus/upstream/*' \
		-not -path './manifests/app-autoscaler/upstream/*' \
	| xargs shellcheck

.PHONY: lint_concourse
lint_concourse:
	pipecleaner concourse/pipelines/* concourse/tasks/*

.PHONY: lint_ruby
lint_ruby:
	bundle exec rubocop

.PHONY: lint_posix_newlines
lint_posix_newlines:
	@# for some reason `git ls-files` is including 'manifests/cf-deployment' in its output...which is a directory
	git ls-files \
	| grep -v \
		-e vendor/ \
		-e manifests/cf-deployment \
		-e manifests/prometheus/upstream \
		-e manifests/app-autoscaler/upstream \
	| xargs ./scripts/test_posix_newline.sh

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

.PHONY: lint
lint: lint_yaml lint_terraform lint_shellcheck lint_concourse lint_ruby lint_posix_newlines lint_symlinks ## Run linting tests

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
	$(eval export ENABLE_AUTODELETE ?= false)
	$(eval export ENABLE_TEST_PIPELINES=true)
	$(eval export ENABLE_AZ_HEALTHCHECK ?= false)
	$(eval export SYSTEM_DNS_ZONE_NAME=$${DEPLOY_ENV}.dev.cloudpipeline.digital)
	$(eval export APPS_DNS_ZONE_NAME=$${DEPLOY_ENV}.dev.cloudpipelineapps.digital)
	$(eval export APPS_HOSTED_ZONE_NAME=dev.cloudpipelineapps.digital)
	$(eval export ALERT_EMAIL_ADDRESS?=govpaas-alerting-dev@digital.cabinet-office.gov.uk)
	$(eval export NEW_ACCOUNT_EMAIL_ADDRESS?=the-multi-cloud-paas-team+dev@digital.cabinet-office.gov.uk)
	$(eval export ENABLE_ALERT_NOTIFICATIONS ?= false)
	$(eval export SKIP_COMMIT_VERIFICATION=true)
	$(eval export ENV_SPECIFIC_BOSH_VARS_FILE=default.yml)
	$(eval export ENV_SPECIFIC_ISOLATION_SEGMENTS_DIR=default)
	$(eval export DISABLE_HEALTHCHECK_DB=true)
	$(eval export CONCOURSE_AUTH_DURATION=48h)
	$(eval export DISABLE_PIPELINE_LOCKING=true)
	$(eval export TEST_HEAVY_LOAD=true)
	$(eval export PAAS_PASSWORD_STORE_DIR?=${HOME}/.paas-pass)
	$(eval export PAAS_HIGH_PASSWORD_STORE_DIR?=${HOME}/.paas-pass)
	$(eval export ENABLE_MORNING_DEPLOYMENT=true)
	$(eval export SLIM_DEV_DEPLOYMENT ?= true)
	$(eval export CA_ROTATION_EXPIRY_DAYS ?= 345)
	$(eval export ENABLE_PAAS_ADMIN_CONTINUOUS_DEPLOY ?= true)
	$(eval export PAAS_ADMIN_INSTANCE_COUNT ?= 3)
	$(eval export DISABLED_AZS)
	$(eval export DISABLE_APP_AUTOSCALER_ACCEPTANCE_TESTS ?= ${SLIM_DEV_DEPLOYMENT})
	$(eval export ENABLE_FAST_STARTUP_AND_SHUTDOWN_CF_ENV ?= true)
	@true

.PHONY: $(filter-out dev%,$(MAKECMDGOALS))
dev%: dev
	$(eval export DEPLOY_ENV=$@)
	@true

.PHONY: stg-lon
stg-lon: ## Set Environment to stg-lon
	$(eval export AWS_ACCOUNT=staging)
	$(eval export MAKEFILE_ENV_TARGET=stg-lon)
	$(eval export PERSISTENT_ENVIRONMENT=true)
	$(eval export ENABLE_AUTO_DEPLOY=true)
	$(eval export ENABLE_AZ_HEALTHCHECK=true)
	$(eval export OUTPUT_TAG_PREFIX=prod-)
	$(eval export SYSTEM_DNS_ZONE_NAME=london.staging.cloudpipeline.digital)
	$(eval export APPS_DNS_ZONE_NAME=london.staging.cloudpipelineapps.digital)
	$(eval export APPS_HOSTED_ZONE_NAME=staging.cloudpipelineapps.digital)
	$(eval export ALERT_EMAIL_ADDRESS=the-multi-cloud-paas-team+stg-lon@digital.cabinet-office.gov.uk)
	$(eval export NEW_ACCOUNT_EMAIL_ADDRESS=${ALERT_EMAIL_ADDRESS})
	$(eval export ENV_SPECIFIC_BOSH_VARS_FILE=stg-lon.yml)
	$(eval export ENV_SPECIFIC_ISOLATION_SEGMENTS_DIR=stg-lon)
	$(eval export DEPLOY_ENV=stg-lon)
	$(eval export TEST_HEAVY_LOAD=true)
	$(eval export PAAS_PASSWORD_STORE_DIR?=${HOME}/.paas-pass)
	$(eval export PAAS_HIGH_PASSWORD_STORE_DIR?=${HOME}/.paas-pass-high)
	$(eval export AWS_DEFAULT_REGION=eu-west-2)
	$(eval export AWS_REGION=eu-west-2)
	$(eval export CA_ROTATION_EXPIRY_DAYS=335)
	$(eval export ENABLE_PAAS_ADMIN_CONTINUOUS_DEPLOY ?= true)
	$(eval export DISABLE_APP_AUTOSCALER_ACCEPTANCE_TESTS ?= false)
	$(eval export DISABLED_AZS)
	@true

.PHONY: prod
prod: ## Set Environment to Production
	$(eval export AWS_ACCOUNT=prod)
	$(eval export MAKEFILE_ENV_TARGET=prod)
	$(eval export PERSISTENT_ENVIRONMENT=true)
	$(eval export ENABLE_AUTO_DEPLOY=true)
	$(eval export ENABLE_AZ_HEALTHCHECK=true)
	$(eval export INPUT_TAG_PREFIX=prod-)
	$(eval export SYSTEM_DNS_ZONE_NAME=cloud.service.gov.uk)
	$(eval export APPS_DNS_ZONE_NAME=cloudapps.digital)
	$(eval export APPS_HOSTED_ZONE_NAME=cloudapps.digital)
	$(eval export ALERT_EMAIL_ADDRESS=the-multi-cloud-paas-team+prod@digital.cabinet-office.gov.uk)
	$(eval export NEW_ACCOUNT_EMAIL_ADDRESS=${ALERT_EMAIL_ADDRESS})
	$(eval export ENV_SPECIFIC_BOSH_VARS_FILE=prod.yml)
	$(eval export ENV_SPECIFIC_ISOLATION_SEGMENTS_DIR=prod)
	$(eval export DISABLE_CF_ACCEPTANCE_TESTS=true)
	$(eval export DEPLOY_ENV=prod)
	$(eval export PAAS_PASSWORD_STORE_DIR?=${HOME}/.paas-pass)
	$(eval export PAAS_HIGH_PASSWORD_STORE_DIR?=${HOME}/.paas-pass-high)
	$(eval export AWS_DEFAULT_REGION=eu-west-1)
	$(eval export AWS_REGION=eu-west-1)
	$(eval export CA_ROTATION_EXPIRY_DAYS=30)
	$(eval export ENABLE_PAAS_ADMIN_CONTINUOUS_DEPLOY ?= true)
	$(eval export DISABLE_APP_AUTOSCALER_ACCEPTANCE_TESTS ?= false)
	$(eval export DISABLED_AZS)
	@true

.PHONY: prod-lon
prod-lon: ## Set Environment to prod-lon
	$(eval export AWS_ACCOUNT=prod)
	$(eval export MAKEFILE_ENV_TARGET=prod-lon)
	$(eval export PERSISTENT_ENVIRONMENT=true)
	$(eval export ENABLE_AUTO_DEPLOY=true)
	$(eval export ENABLE_AZ_HEALTHCHECK=true)
	$(eval export INPUT_TAG_PREFIX=prod-)
	$(eval export SYSTEM_DNS_ZONE_NAME=london.cloud.service.gov.uk)
	$(eval export APPS_DNS_ZONE_NAME=london.cloudapps.digital)
	$(eval export APPS_HOSTED_ZONE_NAME=cloudapps.digital)
	$(eval export ALERT_EMAIL_ADDRESS=the-multi-cloud-paas-team+prod-lon@digital.cabinet-office.gov.uk)
	$(eval export NEW_ACCOUNT_EMAIL_ADDRESS=${ALERT_EMAIL_ADDRESS})
	$(eval export ENV_SPECIFIC_BOSH_VARS_FILE=prod-lon.yml)
	$(eval export ENV_SPECIFIC_ISOLATION_SEGMENTS_DIR=prod-lon)
	$(eval export DISABLE_CF_ACCEPTANCE_TESTS=true)
	$(eval export DEPLOY_ENV=prod-lon)
	$(eval export PAAS_PASSWORD_STORE_DIR?=${HOME}/.paas-pass)
	$(eval export PAAS_HIGH_PASSWORD_STORE_DIR?=${HOME}/.paas-pass-high)
	$(eval export AWS_DEFAULT_REGION=eu-west-2)
	$(eval export AWS_REGION=eu-west-2)
	$(eval export CA_ROTATION_EXPIRY_DAYS=30)
	$(eval export ENABLE_PAAS_ADMIN_CONTINUOUS_DEPLOY ?= true)
	$(eval export DISABLE_APP_AUTOSCALER_ACCEPTANCE_TESTS ?= false)
	$(eval export DISABLED_AZS)
	$(eval export ENABLE_DESTROY=true)
	@true

.PHONY: bosh-cli
bosh-cli:
	@echo "bosh-cli has moved to paas-bootstrap 🐝"

.PHONY: ssh_bosh
ssh_bosh: ## SSH to the bosh server
	@echo "ssh_bosh has moved to paas-bootstrap 🐝"

.PHONY: current-branch
current-branch: ## Deploy current checked out branch
	$(eval export BRANCH=$(shell sh -c "git rev-parse --abbrev-ref HEAD"))
	@true

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
showenv: ## Display environment information
	$(if ${DEPLOY_ENV},,$(error Must pass DEPLOY_ENV=<name>))
	$(if ${MAKEFILE_ENV_TARGET},,$(error Must set MAKEFILE_ENV_TARGET))
	@scripts/showenv.sh

.PHONY: upload-all-secrets
upload-all-secrets: upload-google-oauth-secrets upload-microsoft-oauth-secrets upload-splunk-secrets upload-mailchimp-secrets upload-cronitor-secrets upload-notify-secrets upload-aiven-secrets upload-logit-secrets upload-pagerduty-secrets upload-cyber-secrets upload-paas-trusted-people upload-zendesk-secrets upload-pingdom-secrets upload-psn-secrets upload-slack-secrets

.PHONY: upload-google-oauth-secrets
upload-google-oauth-secrets: check-env ## Decrypt and upload Google Admin Console credentials to Credhub
	$(if $(wildcard ${PAAS_PASSWORD_STORE_DIR}),,$(error Password store ${PAAS_PASSWORD_STORE_DIR} (PAAS_PASSWORD_STORE_DIR) does not exist))
	$(eval export PASSWORD_STORE_DIR=${PAAS_PASSWORD_STORE_DIR})
	@scripts/upload-secrets/upload-google-oauth-secrets.rb

.PHONY: upload-microsoft-oauth-secrets
upload-microsoft-oauth-secrets: check-env ## Decrypt and upload Microsoft Identity credentials to Credhub
	$(if $(wildcard ${PAAS_PASSWORD_STORE_DIR}),,$(error Password store ${PAAS_PASSWORD_STORE_DIR} (PAAS_PASSWORD_STORE_DIR) does not exist))
	$(eval export PASSWORD_STORE_DIR=${PAAS_PASSWORD_STORE_DIR})
	@scripts/upload-secrets/upload-microsoft-oauth-secrets.rb

.PHONY: upload-splunk-secrets
upload-splunk-secrets: check-env ## Decrypt and upload Splunk HEC Tokens to Credhub
	$(if $(wildcard ${PAAS_HIGH_PASSWORD_STORE_DIR}),,$(error Password store ${PAAS_HIGH_PASSWORD_STORE_DIR} (PAAS_HIGH_PASSWORD_STORE_DIR) does not exist))
	$(eval export PASSWORD_STORE_DIR=${PAAS_HIGH_PASSWORD_STORE_DIR})
	@scripts/upload-secrets/upload-splunk-secrets.rb

.PHONY: upload-mailchimp-secrets
upload-mailchimp-secrets: check-env ## Decrypt and upload MailChimp Credentials to Credhub
	$(if $(wildcard ${PAAS_PASSWORD_STORE_DIR}),,$(error Password store ${PAAS_PASSWORD_STORE_DIR} (PAAS_PASSWORD_STORE_DIR) does not exist))
	$(eval export PASSWORD_STORE_DIR=${PAAS_PASSWORD_STORE_DIR})
	@scripts/upload-secrets/upload-mailchimp-secrets.rb

.PHONY: upload-cronitor-secrets
upload-cronitor-secrets: check-env ## Decrypt and upload Cronitor secrets to Credhub
	$(if $(wildcard ${PAAS_PASSWORD_STORE_DIR}),,$(error Password store ${PAAS_PASSWORD_STORE_DIR} (PAAS_PASSWORD_STORE_DIR) does not exist))
	$(eval export PASSWORD_STORE_DIR=${PAAS_PASSWORD_STORE_DIR})
	@scripts/upload-secrets/upload-cronitor-secrets.rb

.PHONY: upload-notify-secrets
upload-notify-secrets: check-env ## Decrypt and upload Notify Credentials to Credhub
	$(if $(wildcard ${PAAS_PASSWORD_STORE_DIR}),,$(error Password store ${PAAS_PASSWORD_STORE_DIR} (PAAS_PASSWORD_STORE_DIR) does not exist))
	$(eval export PASSWORD_STORE_DIR=${PAAS_PASSWORD_STORE_DIR})
	@scripts/upload-secrets/upload-notify-secrets.rb

.PHONY: upload-aiven-secrets
upload-aiven-secrets: check-env ## Decrypt and upload Aiven credentials to Credhub
	$(if $(wildcard ${PAAS_HIGH_PASSWORD_STORE_DIR}),,$(error Password store ${PAAS_HIGH_PASSWORD_STORE_DIR} (PAAS_HIGH_PASSWORD_STORE_DIR) does not exist))
	$(eval export PASSWORD_STORE_DIR=${PAAS_HIGH_PASSWORD_STORE_DIR})
	@scripts/upload-secrets/upload-aiven-secrets.rb

.PHONY: upload-cyber-secrets
upload-cyber-secrets: check-env ## Decrypt and upload Cyber credentials to Credhub
	$(if $(wildcard ${PAAS_PASSWORD_STORE_DIR}),,$(error Password store ${PAAS_PASSWORD_STORE_DIR} (PAAS_PASSWORD_STORE_DIR) does not exist))
	$(eval export PASSWORD_STORE_DIR=${PAAS_PASSWORD_STORE_DIR})
	@scripts/upload-secrets/upload-cyber-secrets.rb

.PHONY: upload-logit-secrets
upload-logit-secrets: check-env ## Decrypt and upload Logit credentials to Credhub
	$(if $(wildcard ${PAAS_PASSWORD_STORE_DIR}),,$(error Password store ${PAAS_PASSWORD_STORE_DIR} (PAAS_PASSWORD_STORE_DIR) does not exist))
	$(eval export PASSWORD_STORE_DIR=${PAAS_PASSWORD_STORE_DIR})
	@scripts/upload-secrets/upload-logit-secrets.rb

.PHONY: upload-pagerduty-secrets
upload-pagerduty-secrets: check-env ## Decrypt and upload pagerduty credentials to Credhub
	$(if $(wildcard ${PAAS_PASSWORD_STORE_DIR}),,$(error Password store ${PAAS_PASSWORD_STORE_DIR} (PAAS_PASSWORD_STORE_DIR) does not exist))
	$(eval export PASSWORD_STORE_DIR=${PAAS_PASSWORD_STORE_DIR})
	@scripts/upload-secrets/upload-pagerduty-secrets.rb

.PHONY: upload-paas-trusted-people
upload-paas-trusted-people: check-env
	@scripts/upload-secrets/upload-paas-trusted-people.sh

.PHONY: upload-zendesk-secrets
upload-zendesk-secrets: check-env ## Decrypt and upload ZenDesk secrets to Credhub
	$(if $(wildcard ${PAAS_PASSWORD_STORE_DIR}),,$(error Password store ${PAAS_PASSWORD_STORE_DIR} (PAAS_PASSWORD_STORE_DIR) does not exist))
	$(eval export PASSWORD_STORE_DIR=${PAAS_PASSWORD_STORE_DIR})
	@scripts/upload-secrets/upload-zendesk-secrets.rb

.PHONY: upload-pingdom-secrets
upload-pingdom-secrets: check-env ## Decrypt and upload Pingdom Credentials to Credhub
	$(if $(wildcard ${PAAS_PASSWORD_STORE_DIR}),,$(error Password store ${PAAS_PASSWORD_STORE_DIR} (PAAS_PASSWORD_STORE_DIR) does not exist))
	$(eval export PASSWORD_STORE_DIR=${PAAS_PASSWORD_STORE_DIR})
	@scripts/upload-secrets/upload-pingdom-secrets.rb

.PHONY: upload-psn-secrets
upload-psn-secrets: check-env ## Decrypt and upload PSN secrets to Credhub
	$(if $(wildcard ${PAAS_PASSWORD_STORE_DIR}),,$(error Password store ${PAAS_PASSWORD_STORE_DIR} (PAAS_PASSWORD_STORE_DIR) does not exist))
	$(eval export PASSWORD_STORE_DIR=${PAAS_PASSWORD_STORE_DIR})
	@scripts/upload-secrets/upload-psn-secrets.rb

.PHONY: upload-slack-secrets
upload-slack-secrets: check-env ## Decrypt and upload Slack credentials to Credhub
	$(if $(wildcard ${PAAS_PASSWORD_STORE_DIR}),,$(error Password store ${PAAS_PASSWORD_STORE_DIR} (PAAS_PASSWORD_STORE_DIR) does not exist))
	$(eval export PASSWORD_STORE_DIR=${PAAS_PASSWORD_STORE_DIR})
	@scripts/upload-secrets/upload-slack-secrets.rb

.PHONY: pingdom
pingdom: check-env ## Use custom Terraform provider to set up Pingdom check
	$(if ${ACTION},,$(error Must pass ACTION=<plan|apply|...>))
	@terraform/scripts/set-up-pingdom.sh ${ACTION}

.PHONY: find_diverged_forks
find_diverged_forks: ## Check all github forks belonging to paas to see if they've diverged upstream
	$(if ${GITHUB_TOKEN},,$(error Must pass GITHUB_TOKEN=<personal github token>))
	./scripts/find_diverged_forks.py alphagov --prefix=paas --github-token=${GITHUB_TOKEN}

.PHONY: run_job
run_job: check-env ## Unbind paas-cf of $JOB in create-cloudfoundry pipeline and then trigger it
	$(if ${JOB},,$(error Must pass JOB=<name>))
	./concourse/scripts/run_job.sh ${JOB}

.PHONY: ssh_concourse
ssh_concourse: check-env ## SSH to the concourse server. Set SSH_CMD to pass a command to execute.
	@echo "ssh_concourse has moved to paas-bootstrap 🐝"

.PHONY: tunnel
tunnel: check-env ## SSH tunnel to internal IPs
	@echo "tunnel has moved to paas-bootstrap 🐝"

.PHONY: stop-tunnel
stop-tunnel: check-env ## Stop SSH tunnel
	@echo "stop-tunnel has moved to paas-bootstrap 🐝"

.PHONY: logit-filters
logit-filters:
	mkdir -p config/logit/output
	docker build -t logit-filters \
		--pull \
		-f $(CURDIR)/config/logit/Dockerfile.generate_logit_filters \
		--build-arg LOGSEARCH_FOR_CLOUDFOUNDRY_TAG=$(LOGSEARCH_FOR_CLOUDFOUNDRY_TAG) \
		--build-arg LOGSEARCH_BOSHRELEASE_TAG=$(LOGSEARCH_BOSHRELEASE_TAG) \
		$(CURDIR)/config/logit
	docker run --rm -it \
		-v $(CURDIR):/mnt:ro \
		-v $(CURDIR)/config/logit/output:/output:rw \
		-w /mnt \
		logit-filters ./scripts/generate_logit_filters.sh
	@echo "updated $(CURDIR)/config/logit/output/generated_logit_filters.conf"

.PHONY: logit-alerts
logit-alerts:
	$(if ${DEPLOY_ENV},,$(error Must pass DEPLOY_ENV=<name>))
	$(if $(wildcard ${PAAS_PASSWORD_STORE_DIR}),,$(error Password store ${PAAS_PASSWORD_STORE_DIR} (PAAS_PASSWORD_STORE_DIR) does not exist))
	$(eval export PASSWORD_STORE_DIR=${PAAS_PASSWORD_STORE_DIR})
	@ruby ./scripts/generate_logit_alerts.rb

.PHONY: show-tenant-comms-addresses
show-tenant-comms-addresses:
	$(eval export API_TOKEN=`cf oauth-token | cut -f 2 -d ' '`)
	$(eval export API_ENDPOINT=https://api.${SYSTEM_DNS_ZONE_NAME})
	$(eval export ADMIN_ENDPOINT=https://admin.${SYSTEM_DNS_ZONE_NAME}/organisations/)
	@cd tools/user_emails/ && go build && API_TOKEN=$(API_TOKEN) ADMIN_ENDPOINT=$(ADMIN_ENDPOINT) ./user_emails

.PHONY: credhub
credhub:
	$(if ${MAKEFILE_ENV_TARGET},,$(error Must set MAKEFILE_ENV_TARGET))
	$(if ${DEPLOY_ENV},,$(error Must pass DEPLOY_ENV=<name>))
	@scripts/credhub_shell.sh

.PHONY: buildpack-upgrade
buildpack-upgrade:
	@scripts/update_buildpacks.sh
	@scripts/create_buildpacks_email.sh

.PHONY: .download-gpg-key
.download-gpg-key:
	$(if $(GPG_KEY_ID),,$(error GPG_KEY_ID is not set))
	$(info Downloading key $(GPG_KEY_ID) from $(GPG_KEYSERVER))
	$(if $(shell $(GPG) --keyserver $(GPG_KEYSERVER) --quiet --recv-key $(GPG_KEY_ID) && echo 'OK'),@true, \
		$(error Failed to download key $(GPG_KEY_ID) from $(GPG_KEYSERVER)))
	$(if $(shell $(GPG) --list-keys | grep $(GPG_KEY_ID) && echo 'OK'),@true, \
		$(error Failed to verify key $(GPG_KEY_ID) was downloaded successfully. Ensure any email verification has been completed.))

.PHONY: .download-gpg-keys
.download-gpg-keys: check-gpg-keys

.PHONY: check-gpg-keys
check-gpg-keys: ## Check all GPG keys specified in .gpg-id are present on the keyserver
	@for key in $$(cat .gpg-id); do \
		$(MAKE) .download-gpg-key GPG_KEY_ID=$$key; \
	done

.PHONY: .upload-gpg-key
.upload-gpg-key:
	$(if $(GPG_KEY_ID),,$(error GPG_KEY_ID is not set))
	$(info Uploading key $(GPG_KEY_ID) to $(GPG_KEYSERVER))
	$(if $(shell $(GPG) --keyserver $(GPG_KEYSERVER) --quiet --send-keys $(GPG_KEY_ID) && echo 'OK'),@true, \
		$(error Failed to upload key $(GPG_KEY_ID) to $(GPG_KEYSERVER)))

.PHONY: upload-gpg-keys
upload-gpg-keys: ## Upload all GPG keys specified in .gpg-id to the keyserver
	@for key in $$(cat .gpg-id); do \
		$(MAKE) .upload-gpg-key GPG_KEY_ID=$$key; \
	done

.PHONY: list-gpg-keys
list-gpg-keys: ## List all the keys in .gpg-id with their names
	@for key in $$(cat .gpg-id); do \
		printf "$${key}: "; \
		$(GPG) --list-keys --with-colons $$key 2> /dev/null | awk -F: '/^uid/ {found = 1; print $$10; exit} END {if (found != 1) {print "*** not found in local keychain ***"}}'; \
	done

.PHONY: update-concourse-gpg-keys
update-concourse-gpg-keys: .download-gpg-keys ## Update vars file for concourse with the latest GPG keys
	@ruby concourse/scripts/generate-public-key-vars.rb

.PHONY: enable_vpc_peer_db_access
enable_vpc_peer_db_access: ## Update vars file for concourse with the latest GPG keys
	@ruby scripts/enable_vpc_peer_db_access.rb

BOUNDARY_POLICY_NAME := S3BrokerUserPermissionsBoundary
IDENTITY_POLICY_NAME := S3BrokerUserCommon
.PHONY: add_permissions_boundary_to_existing_s3_broker_users
add_permissions_boundary_to_existing_s3_broker_users:
	@ruby ./scripts/add_permissions_boundary_to_existing_s3_broker_users.rb --env=$(DEPLOY_ENV) --identity_policy_name=${IDENTITY_POLICY_NAME} --boundary_policy_name=${BOUNDARY_POLICY_NAME} $(ARGS)
