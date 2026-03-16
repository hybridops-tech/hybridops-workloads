# platform/external-secrets

Purpose
- Installs External Secrets Operator as the Kubernetes secret projection layer.

Chosen chart
- Repo: `https://charts.external-secrets.io`
- Chart: `external-secrets`
- Version: `2.1.0`

On-prem contract
- Runs before `platform/secret-stores` and before applications that depend on projected secrets.
- Sync ordering is enforced with Argo CD sync waves.

References
- `ADR-0502`
- `ADR-0504`
