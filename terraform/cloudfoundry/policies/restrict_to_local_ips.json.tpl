{
   "Version": "2012-10-17",
   "Statement": [
     {
       "Effect": "Deny",
       "Resource": "*",
       "Action": "*",
       "Condition": {
         "NotIpAddress": {
           "aws:SourceIp": ${nat_gateway_public_ips}
         }
       }
     }
   ]
}
