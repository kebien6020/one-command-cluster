.PHONY: all setup up down
all: setup up

setup:
	./scripts/setup-backend.sh
	./scripts/setup-ssh.sh

up:
	terraform apply
	./scripts/kubeconfig.sh
	kubectl config use one-command-cluster
	kubectl get nodes

down:
	terraform destroy
