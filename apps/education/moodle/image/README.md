# Moodle Image Strategy

Chosen approach
- Pre-baked custom image derived from the pinned Bitnami Moodle base image.

Pinned source
- Base image: `docker.io/bitnami/moodle:5.0.2-debian-12-r1`
- Plugin source: Microsoft `o365-moodle` tag `v20251223_m500`
- Plugin path copied into the image: `auth/oidc`

Why this approach
- avoids manual plugin installation through the Moodle admin UI
- keeps the runtime reproducible
- keeps the plugin source and version reviewable in Git

Authoritative build file
- `apps/education/moodle/image/Dockerfile`

Expected publish contract
- Publish the image through your standard image pipeline.
- Set in the workload values:
  - `image.registry`
  - `image.repository`
  - `image.tag`
- A tested reference tag for the current maintained lane is:
  - `5.0.2-debian-12-r1-oidc-v20251223_m500-r1`

Anti-drift rules
- Do not revert to manual plugin installation in the Moodle admin UI.
- Do not change the Bitnami base tag without retesting the pinned `auth_oidc` source.
- Do not change the published image name or tag convention without updating the workload values that consume it.
