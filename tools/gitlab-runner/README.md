# GitLab Runner Tools

Purpose
- Render the secret material needed to bootstrap a GitLab Runner without storing the runner token in git.

Files
- `render-artifacts.sh`
  - Generates the Kubernetes Secret manifest for the GitLab runner auth token.

Typical flow

```bash
cd hybridops-workloads
GITLAB_RUNNER_AUTH_TOKEN='glrt-...' ./tools/gitlab-runner/render-artifacts.sh
```

Notes
- Create the runner in GitLab first, then use its authentication token here.
- Apply the rendered secret using your own cluster-access path.
- Keep any private jump-host or environment-specific apply helper outside the public workload contract.
