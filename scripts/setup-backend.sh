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


ensure_bucket() {
  bucket="$1"

  aws s3 mb "s3://${bucket}" || true
}

ensure_backend_tf() {
  bucket="$1"
  region="$2"

  (
    cd ../
    cat >backend.local.tf <<EOF
terraform {
  backend "s3" {
    bucket = "${bucket}"
    key    = "one-command-cluster.tfstate"
    region = "${region}"
  }
}

provider "aws" {
  region = "${region}"

  default_tags {
    tags = {
      project = "one-command-cluster"
    }
  }
}
EOF
  )
}

main() {
  bucket="${1:-kev-tf-one-command-cluster}"
  region="${2:-us-east-1}"

  ensure_bucket "$bucket"
  ensure_backend_tf "$bucket" "$region"
}

main "$@"
