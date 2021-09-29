{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ELBWriteS3Logs",
      "Effect": "Allow",
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::${bucket_name}/*/AWSLogs/*",
      "Principal": {
        "AWS": "arn:aws:iam::${principal}:root"
      }
    },
    {
      "Sid": "AWSDDoSResponseTeamAccessS3Bucket",
      "Effect": "Allow",
      "Action": [
                "s3:GetBucketLocation",
                "s3:GetObject",
                "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::${bucket_name}",
        "arn:aws:s3:::${bucket_name}/*"
      ],
      "Principal": {
        "Service": "drt.shield.amazonaws.com"
      }
    }
  ]
}
