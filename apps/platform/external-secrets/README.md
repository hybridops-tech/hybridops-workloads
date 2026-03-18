# platform/external-secrets

Purpose
- Install External Secrets Operator in the cluster as the steady-state Kubernetes secret projection layer.
- Support workloads that consume external secret authorities such as GCP Secret Manager through `ExternalSecret` resources.

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
