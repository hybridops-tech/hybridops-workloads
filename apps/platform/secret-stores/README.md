# platform/secret-stores

Purpose
- Publish the cluster-level secret store definitions consumed by `ExternalSecret` resources.
- Keep the backend choice declarative and environment-specific.

Current on-prem backend
- `ClusterSecretStore` name: `gcp-secret-manager`
- Backend: GCP Secret Manager
- Bootstrap credential source: `gsm-sa-credentials` in namespace `external-secrets`

On-prem contract
- This app runs after `platform/external-secrets`.
- Applications should reference the store name only; backend credentials stay outside application manifests.

References
- `ADR-0504`
- `platform/k8s/gsm-bootstrap`
