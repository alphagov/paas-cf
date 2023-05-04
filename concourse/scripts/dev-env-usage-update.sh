aws s3api list-buckets | jq -r '.Buckets[].Name|match("gds-paas-dev([0-9][0-9])-state").captures[].string'
