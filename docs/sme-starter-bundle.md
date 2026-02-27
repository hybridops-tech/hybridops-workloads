# SME Starter Bundle

Persona
Growth-stage, knowledge-heavy SMEs (50–500 users) such as training centers, agencies, and schools.
They need identity, collaboration, support, observability, and backups without a full SRE team.

Starter workloads
- Docs assistant (optional): DocsGPT-backed helper for public/internal docs
- Identity: Keycloak (SSO + user lifecycle)
- Collaboration: Nextcloud (files, sharing, calendars)
- Support: Zammad (helpdesk)
- Observability: Prometheus + Grafana (kube-prometheus-stack) and Loki for logs
- Backups: Velero (cluster backup/restore)

Why this bundle sells well
- Covers the day-1 essentials most SMEs ask for.
- Delivers clear value without heavy ops complexity.
- Aligns with HybridOps cost-aware and DR story.

Deployment notes
- All workloads are Helm-based and managed by Argo CD.
- Deploy to on-prem clusters by default; burst/DR clusters can sync the same apps when needed.
