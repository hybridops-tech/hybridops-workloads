# Platform GitLab Runner

Purpose
- Run GitLab CI jobs as Kubernetes pods on the existing RKE2 cluster.
- Keep GitLab itself on `GitLab.com` while using the cluster only for runner execution.

Runtime contract
- Namespace: `ci`
- Argo app: `platform-gitlab-runner`
- Source chart: `gitlab-runner` from `https://charts.gitlab.io`
- Pinned chart version: `0.85.0`

Required secret
- `platform-gitlab-runner-auth`
  - `runner-token`
  - `runner-registration-token`

Recommended mode
- Create the runner in GitLab first and use the runner authentication token (`glrt-*`).
- Store that token in `runner-token`.
- Set `runner-registration-token` to an empty string to satisfy charts that still check for both keys.

Notes
- This app is intentionally not included in `clusters/onprem-learn-stage1`.
- Add it only after the GitLab runner token exists.
- The current cluster has only control-plane nodes online, so the runner is not pinned to a worker-node selector.
- If you later restore dedicated worker nodes, add a node selector or affinity and keep the runner manager off control-plane nodes.
