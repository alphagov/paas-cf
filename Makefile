.PHONY: help test spec lint_yaml lint_terraform lint_shellcheck set_aws_count set_auto_trigger disable_auto_delete check-env-vars dev ci stage prod

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
	cd manifests/bosh-manifest &&\
		bundle exec rspec
	cd manifests/cf-manifest &&\
		bundle exec rspec
	cd tests/bosh-template-renderer &&\
		bundle exec rspec

lint_yaml:
	$(YAMLLINT) -c yamllint.yml .

lint_terraform:
	find terraform -mindepth 1 -maxdepth 1 -type d -print0 | xargs -0 -n 1 -t terraform graph > /dev/null

lint_shellcheck:
	find . -name '*.sh' -print0 | xargs -0 $(SHELLCHECK)

dev: check-env-vars set_aws_account_dev deploy_pipelines ## Deploy Pipelines to Dev Environment

dev-bootstrap: check-env-vars set_aws_account_dev vagrant-deploy

ci: check-env-vars set_aws_account_ci set_auto_trigger disable_auto_delete deploy_pipelines  ## Deploy Pipelines to CI Environment

ci-bootstrap: check-env-vars set_aws_account_ci vagrant-deploy

stage: check-env-vars set_aws_account_stage disable_auto_delete set_auto_trigger set_stage_tag_filter deploy_pipelines  ## Deploy Pipelines to Staging Environment

stage-bootstrap: check-env-vars set_aws_account_stage set_stage_tag_filter vagrant-deploy

prod: check-env-vars set_aws_account_prod disable_auto_delete set_auto_trigger set_prod_tag_filter deploy_pipelines  ## Deploy Pipelines to Production Environment

prod-bootstrap: check-env-vars set_aws_account_prod set_prod_tag_filter vagrant-deploy

vagrant-deploy:
	vagrant/deploy.sh

set_aws_account_dev:
	$(eval export AWS_ACCOUNT=dev)

set_aws_account_ci:
	$(eval export AWS_ACCOUNT=ci)

set_aws_account_stage:
	$(eval export AWS_ACCOUNT=stage)

set_aws_account_prod:
	$(eval export AWS_ACCOUNT=prod)

set_auto_trigger:
	$(eval export ENABLE_AUTO_DEPLOY=true)

set_stage_tag_filter:
	$(eval export PAAS_CF_TAG_FILTER=stage-*)

set_prod_tag_filter:
	$(eval export PAAS_CF_TAG_FILTER=prod-*)

disable_auto_delete:
	$(eval export DISABLE_AUTODELETE=1)

deploy_pipelines:
	concourse/scripts/pipelines-bosh-cloudfoundry.sh
	concourse/scripts/pipelines-failure-testing.sh
