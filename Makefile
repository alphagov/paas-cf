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
	find terraform -mindepth 1 -maxdepth 1 -type d -not -path 'terraform/providers' -not -path 'terraform/scripts' -print0 | xargs -0 -n 1 -t terraform graph > /dev/null

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
	$(eval export TAG_PREFIX=staging-)
	$(eval export SYSTEM_DNS_ZONE_NAME=${DEPLOY_ENV}.ci.cloudpipeline.digital)
	$(eval export APPS_DNS_ZONE_NAME=${DEPLOY_ENV}.ci.cloudpipelineapps.digital)
	$(eval export ALERT_EMAIL_ADDRESS=the-multi-cloud-paas-team+ci@digital.cabinet-office.gov.uk)
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

.PHONY: manually_upload_certs
CERT_PASSWORD_STORE_DIR?=~/.paas-pass-high
manually_upload_certs: ## Manually upload to AWS the SSL certificates for public facing endpoints
	# check password store and if varables are accesible
	$(if ${CERT_PASSWORD_STORE_DIR},,$(error Must pass CERT_PASSWORD_STORE_DIR=<path_to_password_store>))
	$(if $(wildcard ${CERT_PASSWORD_STORE_DIR}),,$(error Password store ${CERT_PASSWORD_STORE_DIR} does not exist))
	@PASSWORD_STORE_DIR=${CERT_PASSWORD_STORE_DIR} pass certs/${AWS_ACCOUNT}/${DEPLOY_ENV}/router_external.crt > /dev/null
	@PASSWORD_STORE_DIR=${CERT_PASSWORD_STORE_DIR} pass certs/${AWS_ACCOUNT}/${DEPLOY_ENV}/router_external.key > /dev/null

	@if ! aws s3 ls s3://${DEPLOY_ENV}-state/cf-certs.tfstate --summarize | grep -q "Total Objects: 0"; then \
		aws s3 cp s3://${DEPLOY_ENV}-state/cf-certs.tfstate cf-certs.tfstate; \
	else \
		echo "No previous cf-certs.tfstate file found in s3://${DEPLOY_ENV}-state/. Assuming first run."; \
	fi

	@terraform apply -var env=${DEPLOY_ENV} \
		-var-file=terraform/${AWS_ACCOUNT}.tfvars \
		-state=cf-certs.tfstate \
		-var router_external_crt="$$(PASSWORD_STORE_DIR=${CERT_PASSWORD_STORE_DIR} pass certs/${AWS_ACCOUNT}/${DEPLOY_ENV}/router_external.crt)" \
		-var router_external_key="$$(PASSWORD_STORE_DIR=${CERT_PASSWORD_STORE_DIR} pass certs/${AWS_ACCOUNT}/${DEPLOY_ENV}/router_external.key)" \
		terraform/cf-certs

	@aws s3 cp cf-certs.tfstate s3://${DEPLOY_ENV}-state/cf-certs.tfstate
	@rm -f cf-certs.tfstate
