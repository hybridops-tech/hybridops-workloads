# Moodle Image Strategy

Chosen approach
- Pre-baked custom image derived from the pinned Bitnami Moodle base image.

Pinned source
- Base image: `docker.io/bitnamilegacy/moodle:5.0.2-debian-12-r2`
- Base image digest: `sha256:df3492f185922381361e8194bffb6d2425accd575992427d571ef12b5c30514c`
- Plugin source: Microsoft `o365-moodle` tag `v20251223_m500`
- Plugin path copied into the image: `auth/oidc`

Why this approach
- avoids manual plugin installation through the Moodle admin UI
- keeps the runtime reproducible
- keeps the plugin source and version reviewable in Git
- preserves exact compatibility with the current Bitnami Moodle chart line (`28.0.0`, app version `5.0.2`)

Authoritative build file
- `apps/education/moodle/image/Dockerfile`

Expected publish contract
- Publish the image through your standard image pipeline.
- Set in the workload values:
  - `image.registry`
  - `image.repository`
  - `image.tag`
- If the package remains private, declare a registry pull secret in the consuming overlay.
- A tested reference tag for the current maintained lane is:
  - `5.0.2-debian-12-r2-oidc-v20251223_m500-r1`

Anti-drift rules
- Do not revert to manual plugin installation in the Moodle admin UI.
- Do not change the pinned legacy base digest without retesting the pinned `auth_oidc` source.
- Move off the legacy base only when the chart line or the source-built base contract is updated deliberately.
- Do not change the published image name or tag convention without updating the workload values that consume it.
