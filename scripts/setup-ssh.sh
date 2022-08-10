#!/bin/sh
set -euo pipefail

# Ensure cd to script location
cd $(dirname "$0")

fatal() {
  >&2 echo "$1"
  exit 1
}

ensure_keys() {
  public_key=$(cat ~/.ssh/id_rsa.pub)

  cat >../keys.local.tf <<EOF
resource "aws_key_pair" "deployer" {
  key_name = "one-command-cluster_deployer"
  public_key = "${public_key}"
}
EOF
}

main() {
  ensure_keys
}

main
