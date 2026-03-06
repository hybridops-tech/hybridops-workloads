# On-Prem Learn Stage 1 Cutover Checklist

Purpose
- Turn the current working dev Learn stack into a publicly reachable setup with the minimum paid surface area.
- Keep public/docs hosting on Cloudflare and expose only the authenticated/runtime services through Cloudflare Tunnel.

Current state
- The dev cluster is healthy for:
  - `auth.hybridops.tech` backend service
  - `entitlements.hybridops.tech` backend service
  - `learn.hybridops.tech` backend service
- Those services are only reachable on private RKE2 addresses today.

Why Cloudflare Tunnel
- The RKE2 ingress addresses are private `10.10.0.x`.
- Buying a domain and creating public DNS records is not enough on its own.
- Cloudflare Tunnel is the lowest-friction way to publish the runtime services without opening inbound NAT or exposing the cluster directly.

What you must do
1. Buy the domain you want to use.
2. Add the zone to Cloudflare and point the registrar nameservers to Cloudflare.
3. In Cloudflare Zero Trust, create one remotely-managed tunnel for the Learn stack.
4. Copy the tunnel token.
5. In the same tunnel, create these public hostname routes:
   - `auth.hybridops.tech` -> `http://platform-keycloak.keycloak.svc.cluster.local:80`
   - `learn.hybridops.tech` -> `http://academy-website.academy.svc.cluster.local:80`
   - `entitlements.hybridops.tech` -> `http://platform-entitlements-api.entitlements.svc.cluster.local:8080`
6. Decide how you want the static/public surfaces hosted:
   - `hybridops.tech`
   - `docs.hybridops.tech`
   - optional `learn-docs.hybridops.tech`
7. Log in to Cloudflare Wrangler from the workstation/account that owns the zone when you are ready to deploy the Worker/static sites.

What I can do after that
1. Render the tunnel secret locally from your token.
2. Apply the `platform/cloudflared-tunnel` workload to the cluster.
3. Add the tunnel app to the Learn Stage 1 Argo target.
4. Verify the three public runtime hosts end to end.
5. Wire the docs Worker route under `docs.hybridops.tech/api/*`.

Static/public hosting split
- `hybridops.tech`: Cloudflare-hosted static/marketing surface
- `docs.hybridops.tech`: Cloudflare-hosted docs
- `auth.hybridops.tech`: Cloudflare Tunnel -> Keycloak in RKE2
- `entitlements.hybridops.tech`: Cloudflare Tunnel -> entitlements API in RKE2
- `learn.hybridops.tech`: Cloudflare Tunnel -> Learn SSR app in RKE2

Exact repo helpers
- Render/app secrets:
  - `hybridops-workloads/tools/onprem-learn-stage1/render-artifacts.sh`
- Apply to the dev cluster through the jump host:
  - `hybridops-workloads/tools/onprem-learn-stage1/apply-dev-via-jump.sh`
- Tunnel workload:
  - `hybridops-workloads/apps/platform/cloudflared-tunnel`

Recommended order
1. Domain purchase and Cloudflare zone setup
2. Cloudflare Tunnel creation and public hostname rules
3. Apply tunnel token secret + tunnel workload
4. Static site deployment on Cloudflare
5. Worker route deployment for Copilot
6. Argo root app cutover for the Learn target
