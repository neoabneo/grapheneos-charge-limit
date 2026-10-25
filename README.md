# grapheneos-charge-limit

A minimal, reviewable integration repository for a user-configurable battery
charge limit on GrapheneOS (Pixel 10 Pro, `blazer`). It contains **patches,
provenance, documentation, and maintenance scripts only** — no GrapheneOS
source tree, no generated build output, no proprietary files, and no binaries.

## Purpose and scope

The feature adds a real, user-selectable charge limit (a stop level and a
resume/start level with a hysteresis) rather than only changing the UI:

- A Settings UI lets the user pick a stop level (50–80%; default 80%).
- `frameworks/base` observes the new global settings and, when the limit is
  enabled, publishes the selected stop level as the system property
  `sota.charge.limit`.
- A new vendor helper (`gos-charge-limit`, a small Rust init service) is
  triggered by `sota.charge.limit=*` and writes the start/stop thresholds to
  the charger sysfs nodes.

This repository intentionally does **not** contain the build-environment
workarounds that were needed to build at the time (see
`docs/build.md`); those are unrelated to the feature.

## Supported device and baseline

- Device / product: **Pixel 10 Pro (`blazer`)**.
- Tested baseline: `blazer-cur-userdebug`, `TARGET_RELEASE=cur`,
  `SKIP_CTS_API_COVERAGE=true`.
- The patches apply cleanly at the exact base commits recorded in
  `docs/patch-provenance.md` and pinned in
  `manifest/baseline-manifest.xml`.

See `docs/baseline.md` for the full build baseline and evidence.

## Relationship to the GrapheneOS source tree

This repository is **standalone**. It is not a fork of GrapheneOS and does not
vendor any AOSP/GrapheneOS sources. It is meant to be applied on top of a
GrapheneOS checkout (a Repo workspace) at the recorded revisions. The patches
are ordinary `git format`-style unified diffs, one per affected repository.

## Inspecting and applying patches

Patches live under `patches/<project>/`:

| Patch | Target repository |
| --- | --- |
| `patches/frameworks-base/frameworks-base.patch` | `frameworks/base` |
| `patches/packages-apps-Settings/settings-app.patch` | `packages/apps/Settings` |
| `patches/system-sepolicy/system-sepolicy.patch` | `system/sepolicy` |
| `patches/vendor-adevtool/vendor-adevtool.patch` | `vendor/adevtool` |

To inspect without changing anything:

```sh
./scripts/apply-patches.sh --source /path/to/grapheneos-17          # dry-run (default)
```

`apply-patches.sh` refuses to run against a dirty worktree, verifies the
recorded base commit and applicability, and requires an explicit `--apply`
plus interactive confirmation before it modifies anything. It never resets,
cleans, stashes, resolves conflicts, or commits.

## Rebuilding and verifying

```sh
./scripts/build-test.sh --source /path/to/grapheneos-17
```

This prints the documented build commands and environment and, with explicit
confirmation, runs the build. It never flashes a device and never syncs,
resets, cleans, or edits sources. See `docs/build.md`.

## Updating patches after upstream changes

See `docs/upstream-maintenance.md` and `scripts/check-upstream.sh`. A patch
that still applies cleanly is **not** proof that it is semantically correct for
a newer GrapheneOS revision.

## What is known to work, and what is not

- **Verified here:** each patch applies cleanly at its recorded base commit and
  reproduces the reviewed source content byte-for-byte (see
  `docs/patch-provenance.md`).
- **Verified elsewhere (reported):** a full `blazer` build reached
  `Build Succeeded: 49531 steps` (~1 h 54 m). See `docs/baseline.md`.
- **NOT confirmed:** the custom feature has **not** been validated end-to-end on
  a physical device. No image in this repository has been flashed. Do not assume
  a device is running this code.
