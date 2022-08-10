#!/bin/sh
set -euo pipefail

# Ensure cd to script location
cd $(dirname "$0")

fatal() {
  >&2 echo "$1"
  exit 1
}

check_deps() {
  >/dev/null which aws || fatal "missing aws cli"
}


main() {
  check_deps

  cd ..
  iid=$(terraform output -raw iid)
  exec aws ec2 get-console-output --instance-id "$iid" --output text
}

main
