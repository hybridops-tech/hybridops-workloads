# HybridOps - HyOps Copilot (Workloads)

Purpose
- Define the Kubernetes-side workload model for HyOps Copilot and the surrounding platform services.
- Keep the docs frontend static and edge-delivered while preserving a stateless cluster recovery model.

Current delivery model (locked)
- Docs frontend (public/member docs builds): static delivery on Cloudflare.
- Copilot API (current preferred path): Cloudflare Worker at the docs origin (`/api/docs-chat`).
- Optional/self-hosted Copilot API path (this repo): Kubernetes workload via Argo CD (`apps/studio/docsgpt`) if required later.
- Stateful dependencies: externalized (HA PostgreSQL and object storage where applicable). No authoritative DB/PV state in the cluster.

What lives where
- `docs.hybridops.tech`: public docs build + HyOps Copilot widget.
- `learn.hybridops.tech`: login/payment/member portal first; Moodle later.
- `academy` docs build (existing): current member-docs basis (may be exposed as a member docs host/path).
- Copilot retrieval corpora: separate public and member indexes (published with docs builds).

Kubernetes workload (optional/self-hosted Copilot API)
- App: `apps/studio/docsgpt`
- Namespace: `docsgpt`
- Exposure: ingress host like `chat-api.<domain>` or internal API host (set via overlay values).

State and DR invariants (anti-drift)
- Cluster workloads are disposable; Argo CD recreates stateless workloads from Git.
- Authoritative state stays external to the cluster.
- Use external HA PostgreSQL for auth/entitlements and any Copilot persistence needs.
- If a cluster is lost, fail over app workloads to cloud and reconnect to promoted external DB endpoints.
- Add backups and a tested DB promotion runbook; replication alone is not sufficient.

Guardrails
- Do not store secrets in Git.
- Enforce strict CORS allowlist to docs origins only.
- Add rate limiting and abuse controls at edge/ingress.
- Retrieval must remain grounded in the docs corpus and return citations.
- Prefer Cloudflare Worker + slim index path unless a self-hosted API is explicitly required.
