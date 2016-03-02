.PHONY: test spec lint_yaml lint_terraform lint_shellcheck set_aws_count set_auto_trigger disable_auto_delete check-env-vars dev ci stage prod

SHELLCHECK=shellcheck
YAMLLINT=yamllint

check-env-vars:
	$(if ${DEPLOY_ENV},,$(error Must pass DEPLOY_ENV=<name>))

test: spec lint_yaml lint_terraform lint_shellcheck

spec:
	cd manifests/bosh-manifest &&\
		bundle exec rspec
	cd manifests/cf-manifest &&\
		bundle exec rspec

lint_yaml:
	$(YAMLLINT) -c yamllint.yml .

lint_terraform:
	find terraform -mindepth 1 -maxdepth 1 -type d -print0 | xargs -0 -n 1 -t terraform graph > /dev/null

lint_shellcheck:
	find . -name '*.sh' -print0 | xargs -0 $(SHELLCHECK)

dev: check-env-vars set_aws_account_dev deploy_pipelines

ci: check-env-vars set_aws_account_ci set_auto_trigger disable_auto_delete deploy_pipelines

stage: check-env-vars set_aws_account_stage disable_auto_delete set_auto_trigger deploy_pipelines

prod: check-env-vars set_aws_account_prod disable_auto_delete set_auto_trigger deploy_pipelines

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

disable_auto_delete:
	$(eval export DISABLE_AUTODELETE=1)

deploy_pipelines:
	concourse/scripts/pipelines-microbosh.sh
	concourse/scripts/pipelines-cloudfoundry.sh
