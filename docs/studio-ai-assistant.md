# HyOps Copilot (Workloads)

Purpose
- Define the workload model around HyOps Copilot and the surrounding platform services.
- Keep the docs frontend static and edge-delivered while preserving a stateless cluster recovery model.

Current delivery model (locked)
- Docs frontend: static delivery on Cloudflare.
- Copilot API (preferred): Cloudflare Worker at the docs origin (`/api/docs-chat`).
- Optional self-hosted Copilot API path: Kubernetes workload via Argo CD (`apps/studio/docsgpt`) if required later.
- Stateful dependencies: externalized. No authoritative DB or PV state in the cluster.

What lives where
- `docs.hybridops.tech`: public docs build + HyOps Copilot widget.
- `learn.hybridops.tech`: login, pricing, account, and Academy access UX.
- `learn-docs.hybridops.tech` or equivalent gated path: paid docs build if kept separate from public docs.
- Copilot retrieval corpora: separate public and paid docs indexes.
- Academy routing metadata: separate module map used for suggestions and CTA linking.

Authorization model
- Public docs and public Copilot are anonymous-safe.
- Paid docs access is driven by explicit docs entitlements (`docs_paid*`).
- Paid Copilot access is driven by `copilot_paid` if sold separately, or by the same docs entitlement if intentionally bundled.
- Academy entitlements (`academy_all`, `academy_track:<slug>`) influence Learn gating and module access, not the public docs corpus by themselves.

Kubernetes workload (optional self-hosted Copilot API)
- App: `apps/studio/docsgpt`
- Namespace: `docsgpt`
- Exposure: ingress host like `chat-api.<domain>` or internal API host

State and DR invariants
- Cluster workloads are disposable; Argo CD recreates stateless workloads from Git.
- Authoritative state stays external to the cluster.
- Use external HA PostgreSQL for auth and entitlements, plus object storage where applicable.
- If a cluster is lost, fail over app workloads and reconnect to promoted external DB endpoints.

Guardrails
- Do not store secrets in Git.
- Enforce strict CORS allowlist to docs origins only.
- Add rate limiting and abuse controls at edge/ingress.
- Retrieval must remain grounded in the docs corpus and return citations.
- Prefer the Cloudflare Worker + slim index path unless a self-hosted API is explicitly required.
