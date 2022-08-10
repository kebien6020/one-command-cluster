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
  >/dev/null which terraform || fatal "missing terraform cli"
  >/dev/null which ssh || fatal "missing ssh"
}

ssh_kubeconf() {
  local ip=$(terraform output -no-color -raw "public_ip")
  local conf
  conf=$(./scripts/ssh.sh "sudo kubectl config view --raw")
  local project="one-command-cluster"
  if [ -z "$conf" ]; then
    >&2 echo "Empty conf $conf"
    return 1
  fi

  local ca=$(<<<"$conf" yq '.clusters[0].cluster["certificate-authority-data"]')
  local server="https://$ip:6443"
  kubectl config set-cluster $project \
    --server "$server" \
    --embed-certs \
    --certificate-authority <(base64 -d <<<"$ca")

  local cert=$(<<<"$conf" yq '.users[0].user["client-certificate-data"]')
  local key=$(<<<"$conf" yq '.users[0].user["client-key-data"]')
  kubectl config set-credentials $project \
    --embed-certs \
    --client-certificate <(base64 -d <<<"$cert") \
    --client-key <(base64 -d <<<"$key")

  kubectl config set-context $project \
    --cluster $project \
    --user $project

  kubectl config get-contexts
}

main() {
  check_deps
  local count=0
	while ! ssh_kubeconf; do
    count=$(($count + 1))
    [ $count -gt 15 ] && return 1

		echo "[kubeconfig] Retrying..."
		sleep 3
	done
}

main
