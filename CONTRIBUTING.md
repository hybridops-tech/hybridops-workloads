# Contributing to HybridOps Workloads

This repository holds the public workload baseline for HybridOps.
Contributions are welcome when they improve a reusable workload, public target,
or the validation behind them.

## Before you start

Read [STANDARD.md](STANDARD.md) first. It defines the boundary between public,
customer-consumable workloads and internal delivery material.

Open an issue before starting a new application family, cluster target, or a
change to an existing application's default behaviour. Direct pull requests are
welcome for contained documentation fixes, manifest corrections, and validation
improvements.

## Scope

- Keep application definitions and overlays reusable across customer
  environments.
- Keep `clusters/` limited to public target groupings.
- Do not add credentials, private addresses, customer-specific domains, or
  internal rollout material.
- Update the relevant operator documentation when a user-visible workload
  behaviour changes.

## Validate the change

Run the validator for every target affected by the change:

```bash
./scripts/validate.sh --strict --target onprem-smoke
./scripts/validate.sh --strict --target onprem-stage1
./scripts/validate.sh --strict --target burst
./scripts/validate.sh --target onprem
```

For a narrowly scoped change, run at least the affected target. Run the full
set when changing shared applications, validation logic, or cluster wiring.

## Pull requests

Keep each pull request focused. Include the target affected, a short summary of
the change, and the validation commands you ran. Call out any checks you could
not run locally.

## Security

Do not include secrets or vulnerability details in a public issue or pull
request. For a suspected security issue, use the
[HybridOps contact form](https://hybridops.tech/contact?intent=general&source=workloads-contributing&target=Security%20report&return=https%3A%2F%2Fdocs.hybridops.tech%2Fguides%2Freference%2Fcontributing%2F).
