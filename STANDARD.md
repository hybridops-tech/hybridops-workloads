# Workloads Standard

This repository is the public workload baseline for HybridOps.

## Purpose

This repo should contain only:

- reusable workload applications
- public cluster targets
- stable operator-facing docs
- public helper scripts that customers can consume

It should not contain:

- internal cutover targets
- private rollout helpers
- business-specific deployment notes
- HybridOps-only domain or product assumptions presented as the product contract

## Rules

### `apps/`

Must contain reusable workload definitions and generic overlays.

### `clusters/`

Must contain only public, customer-consumable target groupings.

### `docs/`

Must contain durable operator docs and stable contracts.

### `scripts/`

Must contain public validation or helper scripts, not internal deployment shortcuts.

## Baseline test

Before publishing a change here, ask:

1. Can a customer consume this with their own repo URL, cluster, and domains?
2. Does this describe the product baseline rather than one internal deployment?
3. Would this still make sense if HybridOps changed its own hosting strategy?
4. Would this still be valid if the internal overlay were completely removed from the export?

If the answer is no, the material does not belong in the public repo.
