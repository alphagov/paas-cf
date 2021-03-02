${jsonencode(
  [for i, cidr in psn_cidrs : { "peer_name": "psn_subnet_${i}", "subnet_cidr": "${cidr}" }]
)}
