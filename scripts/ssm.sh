#!/bin/sh
set -euo pipefail

# Ensure cd to script location
cd $(dirname "$0")

fatal() {
  >&2 echo "$1"
  exit 1
}

check_deps() {
  which aws || fatal "missing aws cli"
}


main() {
  check_deps

  cd ..
  iid=$(terraform output -raw iid)
  exec aws ssm start-session --target "$iid"
}

main
