#!/bin/bash

# Get all CloudFront distribution IDs
aws cloudfront list-distributions --output json | jq -r '.DistributionList.Items[].Id' | while read -r dist_id; do
    dist_info=$(aws cloudfront get-distribution --id "$dist_id" --output json)
    cert_source=$(echo "$dist_info" | jq -r '.Distribution.DistributionConfig.ViewerCertificate.CertificateSource // "default"')

    if [[ "$cert_source" == "acm" ]]; then
        cert_arn=$(echo "$dist_info" | jq -r '.Distribution.DistributionConfig.ViewerCertificate.ACMCertificateArn')
        cert_status=$(aws acm describe-certificate --region us-east-1 --certificate-arn "$cert_arn" --output json | jq -r '.Certificate.Status')

        if [[ "$cert_status" != "ISSUED" ]]; then
            echo "❌ Distribution $dist_id is using an invalid ACM certificate: $cert_status"
        else
          echo "✅ Distribution $dist_id uses a valid ACM certificate"
        fi

    elif [[ "$cert_source" == "iam" ]]; then
        echo "⚠️  Distribution $dist_id is using an IAM certificate (manual check recommended)."
    else
        echo "✅ Distribution $dist_id uses the default CloudFront certificate."
    fi
done