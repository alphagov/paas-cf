#!/bin/sh

cd $(dirname $0)

spiff merge cf-deployment.yml cf-resource-pools.yml cf-jobs.yml cf-properties.yml cf-lamb.yml cf-infrastructure-aws.yml cf-stub_aws.yml
