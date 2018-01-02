{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::${bucket_name}/*/AWSLogs/*",
      "Principal": {
        "AWS": "arn:aws:iam::${principal}:root"
      }
    }
  ]
}
