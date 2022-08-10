#!/bin/bash
set -euo pipefail

# Ensure cd to root
cd $(dirname "$0")/..

fatal() {
  >&2 echo "$1"
  exit 1
}

check_deps() {
  >/dev/null which aws || fatal "missing aws cli"
  >/dev/null which ssh || fatal "missing ssh"
  >/dev/null which terraform || fatal "missing terraform"
}

remote_cmd() {
  local iid=$(terraform output -no-color -raw iid)
  if [[ ! $iid =~ i-[0-9a-f]+ ]]; then fatal "error getting iid from terraform"; fi
  local proxy_opt=$"ProxyCommand=sh -c \"aws ssm start-session --target %h --document-name AWS-StartSSHSession --parameters 'portNumber=%p'\""

  ssh ubuntu@"$iid" -o "$proxy_opt" "$@"
}

main() {
  check_deps
  remote_cmd "$@"
}

main "$@"
