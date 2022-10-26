# k8s-hashicluster-demo
Deployment of HashiCorp stack on Kubernetes (Consul, Vault, Nomad) on Kubernetes

## References
* Kubernetes Docs: [Home](https://kubernetes.io/docs/home/)
* Kubernetes Docs: [K8S v1.25](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/)
* Kubernetes Docs: [Kustomize](https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/#kustomize-feature-list)
* GoogleCloud: [Kustomize Helm](https://cloud.google.com/anthos-config-management/docs/how-to/use-repo-kustomize-helm)
* K8S Special Interest Groups (SIG): [kustomize-chart](https://github.com/kubernetes-sigs/kustomize/blob/master/examples/chart.md)
* Helm-Charts: [ArtifactHub](https://artifacthub.io/)

## How to use
1. Deploy AKS (make aks). This will create an aks-cluster with a single node, using azure-cni networking
2. Deploy Hashicorp applications (Vault, Consul, Nomad). Vault needs to be initialized.
3. TEMPORARY: Copy ACL token & gossipkey from Consul & add to Nomad/Consul config in worker cloud-init.
4. Deploy Worker node (scale-set)

Verify everything is connected by checking Consul / Nomad UI (kubectl port-forward)

## TODO

* H8S: Auto-unseal Vault (Keystore)
* H8S: Auto-init Vault
* H8S: Improve Nomad deployment
* H8S: Front the UI-services with internal loadbalancer.
* H8S: Front the UI-services with internal loadbalancer.
* Workers: Create AKS-identity for retrieving kubeconfig on startup (consul k8s cloud-join) using az-cli
