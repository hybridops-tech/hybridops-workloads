# Platform Apps

Reusable exported apps:
- external-secrets
- secret-stores
- velero
- gitlab-runner

Canonical-only product sources may also exist in this directory, but they are
not part of the exported public workload baseline.

Platform rule:
- Treat platform workloads as stateless application planes; keep authoritative state in external services (HA Postgres/object storage).
