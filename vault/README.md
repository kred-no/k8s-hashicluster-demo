# VAULT

## TERRAFORM: 0-tls-generator/

```bash
# Generate Self-signed TLS-certificates
terraform apply -auto-approve

# Creates 3 files: ca.pem, cert.pem & key.pem
# These are stored under 1-deploy/base/certs
```

## KUBECTL: 1-deploy/

```bash
# Validate
kubectl kustomize --enable-helm base/ | kubectl apply --dry-run=client -f -

# Deploy
kubectl kustomize --enable-helm base/ | kubectl apply --dry-run=none -f -

# Destroy
kubectl kustomize --enable-helm base/ | kubectl delete --dry-run=none -f -
```

## TERRAFORM: 2-configure/

TODO