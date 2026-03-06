# GitLab Runner Tools

Purpose
- Bootstrap a GitLab Runner on the existing RKE2 cluster without storing the runner token in git.

Files
- `render-artifacts.sh`
  - Generates the Kubernetes Secret manifest for the GitLab runner auth token.
- `apply-via-jump.sh`
  - Applies the secret and the Argo `Application` through `hybridhub`.

Typical flow

```bash
cd hybridops-workloads
GITLAB_RUNNER_AUTH_TOKEN='glrt-...' ./tools/gitlab-runner/render-artifacts.sh
./tools/gitlab-runner/apply-via-jump.sh
```

Notes
- Create the runner in GitLab first, then use its authentication token here.
- This tooling assumes the current workstation-to-cluster path goes via `root@192.168.0.27`.
