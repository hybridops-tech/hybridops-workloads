# Moodle Image Strategy

Chosen approach
- Pre-baked custom image derived from the pinned Bitnami Moodle base image.

Base image
- `docker.io/bitnami/moodle:5.0.2-debian-12-r1`

Required addition
- Moodle OpenID Connect plugin: `auth_oidc`

Why this approach
- avoids manual plugin installation through the Moodle admin UI
- keeps the runtime reproducible
- matches the GitOps deployment model used for the rest of the workload repo

What the image must contain
- the upstream Bitnami Moodle runtime
- `auth_oidc` present before first boot
- no interactive setup steps required to enable the plugin files

Expected publish contract
- publish the built image to your registry
- set in `apps/education/moodle/base/values.yaml`:
  - `image.registry`
  - `image.repository`
  - `image.tag`

Important note
- This repo records the image packaging strategy and values contract.
- It does not yet ship a final build pipeline for the Moodle custom image.
- Build the image only after the exact plugin source/version is chosen and tested against the pinned Bitnami base image.
