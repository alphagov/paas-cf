{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": "*",
            "Condition": {
                "StringNotEquals": {
                    "aws:ResourceAccount": ${platform_aws_account_id}
                }
            }
        }
    ]
}
