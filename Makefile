.PHONY: help test spec lint_yaml lint_terraform lint_shellcheck check-env-vars

.DEFAULT_GOAL := help

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

SHELLCHECK=shellcheck
YAMLLINT=yamllint

check-env-vars:
	$(if ${DEPLOY_ENV},,$(error Must pass DEPLOY_ENV=<name>))

test: spec lint_yaml lint_terraform lint_shellcheck ## Run linting tests

spec:
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
	cd tests/bosh-template-renderer &&\
		bundle exec rspec

lint_yaml:
	$(YAMLLINT) -c yamllint.yml .

lint_terraform: dev
	$(eval export TF_VAR_system_dns_zone_name=$SYSTEM_DNS_ZONE_NAME)
	$(eval export TF_VAR_apps_dns_zone_name=$APPS_DNS_ZONE_NAME)
	find terraform -mindepth 1 -maxdepth 1 -type d -print0 | xargs -0 -n 1 -t terraform graph > /dev/null

lint_shellcheck:
	find . -name '*.sh' -print0 | xargs -0 $(SHELLCHECK)

.PHONY: globals
globals:
	$(eval export AWS_DEFAULT_REGION=eu-west-1)
	@true

.PHONY: dev
dev: globals check-env-vars ## Set Environment to DEV
	$(eval export MAKEFILE_ENV_TARGET=dev)
	$(eval export AWS_ACCOUNT=dev)
	$(eval export ENABLE_AUTODELETE=true)
	$(eval export SYSTEM_DNS_ZONE_NAME=${DEPLOY_ENV}.dev.cloudpipeline.digital)
	$(eval export APPS_DNS_ZONE_NAME=${DEPLOY_ENV}.dev.cloudpipelineapps.digital)
	@true

.PHONY: ci
ci: globals check-env-vars ## Set Environment to CI
	$(eval export MAKEFILE_ENV_TARGET=ci)
	$(eval export AWS_ACCOUNT=ci)
	$(eval export ENABLE_AUTO_DEPLOY=true)
	$(eval export SKIP_UPLOAD_GENERATED_CERTS=true)
	$(eval export TAG_PREFIX=stage-)
	$(eval export SYSTEM_DNS_ZONE_NAME=${DEPLOY_ENV}.ci.cloudpipeline.digital)
	$(eval export APPS_DNS_ZONE_NAME=${DEPLOY_ENV}.ci.cloudpipelineapps.digital)
	@true

.PHONY: stage
stage: globals check-env-vars ## Set Environment to Staging
	$(eval export MAKEFILE_ENV_TARGET=stage)
	$(eval export AWS_ACCOUNT=stage)
	$(eval export ENABLE_AUTO_DEPLOY=true)
	$(eval export SKIP_UPLOAD_GENERATED_CERTS=true)
	$(eval export TAG_PREFIX=prod-)
	$(eval export PAAS_CF_TAG_FILTER=stage-*)
	$(eval export SYSTEM_DNS_ZONE_NAME=staging.cloudpipeline.digital)
	$(eval export APPS_DNS_ZONE_NAME=staging.cloudpipelineapps.digital)
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
	@concourse/scripts/environment.sh
