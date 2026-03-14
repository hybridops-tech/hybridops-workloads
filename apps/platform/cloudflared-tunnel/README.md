# Platform Cloudflared Tunnel

Purpose
- Publish the private RKE2 Learn stack through Cloudflare Tunnel instead of exposing cluster node IPs directly.
- Keep `auth.hybridops.tech`, `learn.hybridops.tech`, and `entitlements.hybridops.tech` on outbound-only connectivity.

Runtime contract
- Namespace: `cloudflare-tunnel`
- Deployment: `platform-cloudflared-tunnel`
- Runtime model: `cloudflare/cloudflared` with a remotely-managed tunnel token

Required secret
- `platform-cloudflared-tunnel-secrets`
  - `TUNNEL_TOKEN`
  - authoritative path: runtime vault -> GCP Secret Manager -> `ExternalSecret`
  - direct long-lived `Secret` creation is break-glass only

Cloudflare public hostname mappings
- `auth.hybridops.tech` -> `http://platform-keycloak.keycloak.svc.cluster.local:80`
- `learn.hybridops.tech` -> `http://academy-website.academy.svc.cluster.local:80`
- `entitlements.hybridops.tech` -> `http://platform-entitlements-api.entitlements.svc.cluster.local:8080`

Notes
- Add this workload only after the Cloudflare tunnel token exists in the runtime vault and GCP Secret Manager.
- Because the tunnel is outbound-only, you do not need public NAT rules to the cluster for these three hosts.
- For Stage 1, the public/docs static surfaces remain on Cloudflare hosting and only the authenticated/runtime surfaces go through the tunnel.
- `cloudflare/cloudflared:latest` is acceptable for the current dev path; pin a tested tag before calling the edge deployment release-grade.
