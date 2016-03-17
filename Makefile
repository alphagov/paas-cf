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

lint_terraform: set_env_class_dev
	$(eval export TF_VAR_system_dns_zone_name=$SYSTEM_DNS_ZONE_NAME)
	$(eval export TF_VAR_apps_dns_zone_name=$APPS_DNS_ZONE_NAME)
	find terraform -mindepth 1 -maxdepth 1 -type d -print0 | xargs -0 -n 1 -t terraform graph > /dev/null

lint_shellcheck:
	find . -name '*.sh' -print0 | xargs -0 $(SHELLCHECK)

.PHONY: dev
dev: check-env-vars set_env_class_dev ## Set environment to DEV

.PHONY: ci
ci: check-env-vars set_env_class_ci ## Set environment to CI

.PHONY: stage
stage: check-env-vars set_env_class_stage  ## Set Envirnoment to Staging

.PHONY: prod
prod: check-env-vars set_env_class_prod ## Set Envirnoment to Production 

.PHONY: bootstrap
bootstrap: ## Start bootsrap 
	vagrant/deploy.sh

.PHONY: bootstrap-destroy
bootstrap-destroy: ## Destroy bootsrap 
	./vagrant/destroy.sh

.PHONY: bosh-cli
bosh-cli: ## Create interactive connnection to BOSH container
	concourse/scripts/bosh-cli.sh $(DEPLOY_ENV)

.PHONY: set_env_class_dev
set_env_class_dev:
	$(eval export MAKEFILE_ENV_TARGET=dev)
	$(eval export AWS_ACCOUNT=dev)
	$(eval export ENABLE_AUTODELETE=true)
	$(eval export SYSTEM_DNS_ZONE_NAME=${DEPLOY_ENV}.dev.cloudpipeline.digital)
	$(eval export APPS_DNS_ZONE_NAME=${DEPLOY_ENV}.dev.cloudpipelineapps.digital)

.PHONY: set_env_class_ci
set_env_class_ci:
	$(eval export MAKEFILE_ENV_TARGET=ci)
	$(eval export AWS_ACCOUNT=ci)
	$(eval export ENABLE_AUTO_DEPLOY=true)
	$(eval export TAG_PREFIX=stage-)
	$(eval export SYSTEM_DNS_ZONE_NAME=${DEPLOY_ENV}.ci.cloudpipeline.digital)
	$(eval export APPS_DNS_ZONE_NAME=${DEPLOY_ENV}.ci.cloudpipelineapps.digital)

.PHONY: set_env_class_stage
set_env_class_stage:
	$(eval export MAKEFILE_ENV_TARGET=stage)
	$(eval export AWS_ACCOUNT=stage)
	$(eval export ENABLE_AUTO_DEPLOY=true)
	$(eval export PAAS_CF_TAG_FILTER=stage-*)
	$(eval export SYSTEM_DNS_ZONE_NAME=staging.cloudpipeline.digital)
	$(eval export APPS_DNS_ZONE_NAME=staging.cloudpipelineapps.digital)

.PHONY: set_env_class_prod
set_env_class_prod:
	$(eval export MAKEFILE_ENV_TARGET=prod)
	$(eval export AWS_ACCOUNT=prod)
	$(eval export ENABLE_AUTO_DEPLOY=true)
	$(eval export PAAS_CF_TAG_FILTER=prod-*)
	$(eval export SYSTEM_DNS_ZONE_NAME=cloud.service.gov.uk)
	$(eval export APPS_DNS_ZONE_NAME=cloudapps.digital)

.PHONY: pipelines
pipelines: ## Upload pipelines to Concourse
	concourse/scripts/pipelines-bosh-cloudfoundry.sh
