#!/bin/sh -eu
if [ $# -lt 3 ]; then
  echo "Missing arguments. Usage: $0 root_key sub_key filename" 1>&2
  exit 1
fi

if [ ! -r "$3" ]; then
  echo "'$3': No such file or directory or not readable" 1>&2
  exit 1
fi

cat <<EOF
---
${1}:
  ${2}: |
EOF
sed "s/^/    /" "$3"
