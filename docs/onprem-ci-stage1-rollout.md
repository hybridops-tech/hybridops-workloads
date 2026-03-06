# On-Prem CI Stage 1 Rollout

Purpose
- Add GitLab CI execution to the existing RKE2 cluster without self-hosting GitLab.
- Keep GitLab on `GitLab.com` and run only the runner manager/job pods in-cluster.

What this target contains
- `platform/gitlab-runner`

Recommended model
- `GitLab.com Free` for source control and pipeline orchestration
- `platform-gitlab-runner` in RKE2 for job execution
- `Argo CD` for workload deployment
- `Cloudflare` for public static hosting, Workers, and tunnel edge

What you do in GitLab
- Create a project-level or group-level runner in `GitLab.com`.
- Copy the runner authentication token (`glrt-*`).
- Decide the tags and protection policy in the GitLab UI rather than in chart values.
- Add CI/CD variables in the relevant projects before using deploy jobs:
  - `CLOUDFLARE_API_TOKEN`
  - `CLOUDFLARE_ACCOUNT_ID`

Required secret
- `platform-gitlab-runner-auth` in namespace `ci`
  - `runner-token`
  - `runner-registration-token`

Token guidance
- Create the runner in GitLab first and use the runner authentication token (`glrt-*`).
- Do not put the token in git.
- Render the secret locally with:

```bash
GITLAB_RUNNER_AUTH_TOKEN='glrt-...' ./tools/gitlab-runner/render-artifacts.sh
```

Apply path from this workstation

```bash
./tools/gitlab-runner/apply-via-jump.sh
```

Bootstrap as a root Argo app later
- Use target path `clusters/onprem-ci-stage1`
- Keep it as a separate root app from `onprem-learn-stage1`

Notes
- The current cluster only shows control-plane nodes online, so the runner manager is not constrained to worker nodes yet.
- Once worker nodes are available again, add a node selector or affinity and move CI jobs off the control-plane nodes.
- The starter `.gitlab-ci.yml` files now exist in both `hybridops-workloads` and `hybridops-docs`.
