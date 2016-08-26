.PHONY: help test spec lint_yaml lint_terraform lint_shellcheck lint_concourse check-env-vars

.DEFAULT_GOAL := help

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

SHELLCHECK=shellcheck
YAMLLINT=yamllint

DEPLOY_ENV_MAX_LENGTH=15
DEPLOY_ENV_VALID_LENGTH=$(shell if [ $${\#DEPLOY_ENV} -gt $(DEPLOY_ENV_MAX_LENGTH) ]; then echo ""; else echo "OK"; fi)
DEPLOY_ENV_VALID_CHARS=$(shell if echo $(DEPLOY_ENV) | grep -q '^[a-zA-Z0-9-]*$$'; then echo "OK"; else echo ""; fi)

check-env-vars:
	$(if ${DEPLOY_ENV},,$(error Must pass DEPLOY_ENV=<name>))
	$(if ${DEPLOY_ENV_VALID_LENGTH},,$(error Sorry, DEPLOY_ENV ($(DEPLOY_ENV)) has a max length of $(DEPLOY_ENV_MAX_LENGTH), otherwise derived names will be too long))
	$(if ${DEPLOY_ENV_VALID_CHARS},,$(error Sorry, DEPLOY_ENV ($(DEPLOY_ENV)) must use only alphanumeric chars and hyphens, otherwise derived names will be malformatted))

test: spec lint_yaml lint_terraform lint_shellcheck lint_concourse lint_ruby ## Run linting tests

spec:
	cd scripts &&\
		BUNDLE_GEMFILE=Gemfile bundle exec rspec
	cd concourse/scripts &&\
		go test
	cd concourse/scripts &&\
		bundle exec rspec
	cd manifests/shared &&\
		bundle exec rspec
	cd manifests/concourse-manifest &&\
		bundle exec rspec
	cd manifests/bosh-manifest &&\
		bundle exec rspec
	cd manifests/cf-manifest &&\
		bundle exec rspec
	cd platform-tests/bosh-template-renderer &&\
		bundle exec rspec

lint_yaml:
	find . -name '*.yml' -not -path '*/vendor/*' | xargs $(YAMLLINT) -c yamllint.yml

lint_terraform: dev
	$(eval export TF_VAR_system_dns_zone_name=$SYSTEM_DNS_ZONE_NAME)
	$(eval export TF_VAR_apps_dns_zone_name=$APPS_DNS_ZONE_NAME)
	find terraform -mindepth 1 -maxdepth 1 -type d -not -path 'terraform/providers' -not -path 'terraform/scripts' -print0 | xargs -0 -n 1 -t terraform graph > /dev/null

lint_shellcheck:
	find . -name '*.sh' -not -path '*/vendor/*' | xargs $(SHELLCHECK)

lint_concourse:
	cd .. && python paas-cf/concourse/scripts/pipecleaner.py paas-cf/concourse/pipelines/*.yml

.PHONY: lint_ruby
lint_ruby:
	bundle exec govuk-lint-ruby

.PHONY: list_merge_keys
list_merge_keys: ## List all GPG keys allowed to sign merge commits.
	@for key in $$(cat .gpg-id); do \
		printf "$${key}: "; \
		gpg --list-keys --with-colons $$key 2> /dev/null | awk -F: '/^pub/ {found = 1; print $$10} END {if (found != 1) {print "*** not found in local keychain ***"}}'; \
	done

.PHONY: globals
globals:
	$(eval export AWS_DEFAULT_REGION=eu-west-1)
	@true

.PHONY: dev
dev: globals check-env-vars ## Set Environment to DEV
	$(eval export MAKEFILE_ENV_TARGET=dev)
	$(eval export AWS_ACCOUNT=dev)
	$(eval export ENABLE_DESTROY=true)
	$(eval export ENABLE_AUTODELETE=true)
	$(eval export SYSTEM_DNS_ZONE_NAME=${DEPLOY_ENV}.dev.cloudpipeline.digital)
	$(eval export APPS_DNS_ZONE_NAME=${DEPLOY_ENV}.dev.cloudpipelineapps.digital)
	$(eval export SKIP_COMMIT_VERIFICATION=true)
	$(eval export ENV_SPECIFIC_CF_MANIFEST=cf-default.yml)
	$(eval export ENABLE_HEALTHCHECK_DB=false)
	@true

.PHONY: ci
ci: globals check-env-vars ## Set Environment to CI
	$(eval export MAKEFILE_ENV_TARGET=ci)
	$(eval export AWS_ACCOUNT=ci)
	$(eval export ENABLE_AUTO_DEPLOY=true)
	$(eval export TAG_PREFIX=staging-)
	$(eval export SYSTEM_DNS_ZONE_NAME=${DEPLOY_ENV}.ci.cloudpipeline.digital)
	$(eval export APPS_DNS_ZONE_NAME=${DEPLOY_ENV}.ci.cloudpipelineapps.digital)
	$(eval export ALERT_EMAIL_ADDRESS=the-multi-cloud-paas-team+ci@digital.cabinet-office.gov.uk)
	$(eval export NEW_ACCOUNT_EMAIL_ADDRESS=${ALERT_EMAIL_ADDRESS})
	$(eval export ENV_SPECIFIC_CF_MANIFEST=cf-default.yml)
	@true

.PHONY: staging
staging: globals check-env-vars ## Set Environment to Staging
	$(eval export MAKEFILE_ENV_TARGET=staging)
	$(eval export AWS_ACCOUNT=staging)
	$(eval export ENABLE_AUTO_DEPLOY=true)
	$(eval export SKIP_UPLOAD_GENERATED_CERTS=true)
	$(eval export TAG_PREFIX=prod-)
	$(eval export PAAS_CF_TAG_FILTER=staging-*)
	$(eval export SYSTEM_DNS_ZONE_NAME=staging.cloudpipeline.digital)
	$(eval export APPS_DNS_ZONE_NAME=staging.cloudpipelineapps.digital)
	$(eval export ALERT_EMAIL_ADDRESS=the-multi-cloud-paas-team+staging@digital.cabinet-office.gov.uk)
	$(eval export NEW_ACCOUNT_EMAIL_ADDRESS=${ALERT_EMAIL_ADDRESS})
	$(eval export ENV_SPECIFIC_CF_MANIFEST=cf-default.yml)
	$(eval export ENABLE_CF_ACCEPTANCE_TESTS=false)
	@true

.PHONY: prod
prod: globals check-env-vars ## Set Environment to Production
	$(eval export MAKEFILE_ENV_TARGET=prod)
	$(eval export AWS_ACCOUNT=prod)
	$(eval export ENABLE_AUTO_DEPLOY=true)
	$(eval export SKIP_UPLOAD_GENERATED_CERTS=true)
	$(eval export PAAS_CF_TAG_FILTER=prod-*)
	$(eval export SYSTEM_DNS_ZONE_NAME=cloud.service.gov.uk)
	$(eval export APPS_DNS_ZONE_NAME=cloudapps.digital)
	$(eval export ALERT_EMAIL_ADDRESS=the-multi-cloud-paas-team+prod@digital.cabinet-office.gov.uk)
	$(eval export NEW_ACCOUNT_EMAIL_ADDRESS=${ALERT_EMAIL_ADDRESS})
	$(eval export ENV_SPECIFIC_CF_MANIFEST=cf-prod.yml)
	$(eval export ENABLE_CF_ACCEPTANCE_TESTS=false)
	@true

.PHONY: bootstrap
bootstrap: ## Start bootstrap
	vagrant/deploy.sh

.PHONY: bootstrap-destroy
bootstrap-destroy: ## Destroy bootstrap
	./vagrant/destroy.sh

.PHONY: bosh-cli
bosh-cli: ## Create interactive connnection to BOSH container
	concourse/scripts/bosh-cli.sh

.PHONY: pipelines
pipelines: ## Upload pipelines to Concourse
	concourse/scripts/pipelines-bosh-cloudfoundry.sh

.PHONY: showenv
showenv: ## Display environment information
	$(eval export TARGET_CONCOURSE=deployer)
	@echo CONCOURSE_IP=$$(aws ec2 describe-instances \
		--filters 'Name=tag:Name,Values=concourse/0' "Name=key-name,Values=${DEPLOY_ENV}_concourse_key_pair" \
		--query 'Reservations[].Instances[].PublicIpAddress' --output text)
	@concourse/scripts/environment.sh

.PHONY: manually_upload_certs
CERT_PASSWORD_STORE_DIR?=~/.paas-pass-high
manually_upload_certs: ## Manually upload to AWS the SSL certificates for public facing endpoints
	# check password store and if varables are accesible
	$(if ${CERT_PASSWORD_STORE_DIR},,$(error Must pass CERT_PASSWORD_STORE_DIR=<path_to_password_store>))
	$(if $(wildcard ${CERT_PASSWORD_STORE_DIR}),,$(error Password store ${CERT_PASSWORD_STORE_DIR} does not exist))
	@terraform/scripts/manually-upload-certs.sh

.PHONY: pingdom
pingdom: ## Use custom Terraform provider to set up Pingdom check
	$(eval export PASSWORD_STORE_DIR?=~/.paas-pass)
	$(eval export PINGDOM_CONTACT_IDS=11089310)
	@terraform/scripts/set-up-pingdom.sh

merge_pr: ## Merge a PR. Must specify number in a PR=<number> form.
	$(if ${PR},,$(error Must pass PR=<number>))
	./scripts/merge_pr.rb --pr ${PR}

find_diverged_forks: ## Check all github forks belonging to paas to see if they've diverged upstream
	$(if ${GITHUB_TOKEN},,$(error Must pass GITHUB_TOKEN=<personal github token>))
	./scripts/find_diverged_forks.py alphagov --prefix=paas --extra-repo=cf-release --extra-repo=graphite-nozzle --github-token=${GITHUB_TOKEN}

.PHONY: run_job
run_job: check-env-vars ##  Unbind paas-cf of $JOB in create-bosh-cloudfoundry pipeline and then trigger it
	$(if ${JOB},,$(error Must pass JOB=<name>))
	./concourse/scripts/run_job.sh ${JOB}
