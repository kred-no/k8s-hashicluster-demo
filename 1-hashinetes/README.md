# KUBERNETES

## Vault Init/Unseal (manual)

```bash
# Exec into container
kubectl -n <namespace> exec <server> -it -- ash

# Init Vault with 1 key & unseal
touch /vault/init.json && vault operator init -tls-skip-verify=true -key-shares=1 -key-threshold=1 -format=json|tee -a /vault/init.json
vault operator unseal -tls-skip-verify $(sed -n '6p' < /vault/init.json|xargs)
exit

# Verify you can log in with root token @ https://localhost:8200
kubectl -n <namespace> port-forward svc/<vault-ui> 8200:8200
```
