# Pipecleaner

Pipecleaner is a go command line utility for validating Concourse pipelines.

## Installation

```
go get -u github.com/alphagov/paas-cf/tools/pipecleaner
```

## Usage

```
# Validate a single pipeline
pipecleaner concourse/pipelines/pipeline1.yml

# Validate many pipelines
pipecleaner concourse/pipelines/*.yml concourse/other-pipelines/*.yml

# Validate tasks
pipecleaner concourse/tasks/*.yml

# Validate pipelines and tasks
pipecleaner concourse/pipelines/*.yml concourse/tasks/*.yml
```

## Features

1. Uses Concourse's native validation
1. Runs [Shellcheck](https://www.shellcheck.net/)
    - works inside `sh`/`bash`/`dash`/`ash` code blocks
    - disable with `--shellcheck=false`
1. Runs [Rubocop](https://www.rubocop.org/en/stable/)
    - works inside `ruby` code blocks
    - disable with `--rubocop=false`
1. Checks if secrets are interpolated
    - disable with `--secrets=false`
1. Checks if all resources are used
    - disable with `--all-resources-used=false`

For full usage, see `--help`
