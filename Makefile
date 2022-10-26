.PHONY: aks h8s vms xaks xh8s xvms vault-init up clean

aks:
	@terraform -chdir=./0-aks init
	@terraform -chdir=./0-aks validate
	@terraform -chdir=./0-aks apply -auto-approve

h8s:
	@terraform -chdir=./1-hashinetes init
	@terraform -chdir=./1-hashinetes validate
	@terraform -chdir=./1-hashinetes apply -auto-approve

vms:
	@terraform -chdir=./2-workers init
	@terraform -chdir=./2-workers validate
	@terraform -chdir=./2-workers apply -auto-approve

vault-init:
	@export KUBECONFIG=$(pwd)/0-aks/kubeconfig
	@kubectl -n vault exec statefulset.apps/vault -it -- ash -c "touch /vault/data/init.json && vault operator init -tls-skip-verify=true -key-shares=5 -key-threshold=3 -format=json|tee -a /vault/data/init.json; exit 0"
	@kubectl -n vault exec statefulset.apps/vault -it -- ash -c "vault status -tls-skip-verify; exit 0"

xaks:
	@terraform -chdir=./0-aks destroy

xh8s:
	@terraform -chdir=./1-hashinetes destroy

xvms:
	@terraform -chdir=./2-workers destroy

up: aks h8s vms

clean: xvms xh8s xaks
	@rm -rf ./2-workers/.terraform/*
	@rm -rf ./1-hashinetes/.terraform/*
	@rm -rf ./0-aks/.terraform/*
	@rm -rf ./statefiles/*
