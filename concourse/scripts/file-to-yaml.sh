#!/bin/sh -e

cat <<EOF
---
${1}:
  ${2}: |
EOF
sed "s/^/    /" "$3"
