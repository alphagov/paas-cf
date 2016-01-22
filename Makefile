.PHONY: test spec lint_terraform lint_shellcheck

test: spec lint_terraform lint_shellcheck

spec:
	cd manifests/bosh-manifest &&\
		bundle exec rspec
	cd manifests/cf-manifest &&\
		bundle exec rspec

lint_terraform:
	find terraform -mindepth 1 -maxdepth 1 -type d -print0 | xargs -0 -n 1 -t terraform graph > /dev/null

lint_shellcheck:
	find . -name '*.sh' -print0 | xargs -0 shellcheck
