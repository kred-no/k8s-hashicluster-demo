.PHONY: aks h8s vms xaks xh8s xvms vault-init up clean

aks:
	@terraform -chdir=./0-aks init
	@terraform -chdir=./0-aks validate
	@terraform -chdir=./0-aks apply

h8s:
	@terraform -chdir=./1-h8s init
	@terraform -chdir=./1-h8s validate
	@terraform -chdir=./1-h8s apply

pkr-init:
	@terraform -chdir=./2-packer-builds/terraform-packer init
	@terraform -chdir=./2-packer-builds/terraform-packer validate
	@terraform -chdir=./2-packer-builds/terraform-packer apply

vms:
	@terraform -chdir=./3-external-nodes init
	@terraform -chdir=./3-external-nodes validate
	@terraform -chdir=./3-external-nodes apply

vault-init:
	@export KUBECONFIG=$(pwd)/0-aks/kubeconfig
	@kubectl -n vault exec statefulset.apps/vault -it -- ash -c "touch /vault/data/init.json && vault operator init -tls-skip-verify=true -key-shares=5 -key-threshold=3 -format=json|tee -a /vault/data/init.json; exit 0"
	@kubectl -n vault exec statefulset.apps/vault -it -- ash -c "vault status -tls-skip-verify; exit 0"

xaks:
	@terraform -chdir=./0-aks destroy

xh8s:
	@terraform -chdir=./1-h8s destroy

xpkr-init:
	@terraform -chdir=./2-packer-builds/terraform-packer destroy

xvms:
	@terraform -chdir=./2-external-nodes destroy

up: aks h8s vms

clean: xvms xh8s xpkr-init xaks
	@rm -rf ./3-external-nodes/.terraform/*
	@rm -rf ./2-packer-builds/terraform-packer/.terraform/*
	@rm -rf ./1-h8s/.terraform/*
	@rm -rf ./0-aks/.terraform/*
	@rm -rf ./statefiles/*
