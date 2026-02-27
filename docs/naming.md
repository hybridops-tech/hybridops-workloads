# Naming

Directory naming:
- apps/<domain>/<app>
- clusters/<target>

Argo CD Application names:
- <domain>-<app> (example: platform-keycloak)

Labels:
- hyops.domain
- hyops.app
- hyops.profile (optional)
- hyops.env (optional)

Module refs (HybridOps.Core):
- Use slash-separated identifiers such as core/hetzner/edge-network.
- Do not encode time tags in module_ref.
