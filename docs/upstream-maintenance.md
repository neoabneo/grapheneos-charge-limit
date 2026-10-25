# Upstream maintenance

## The core warning

**A patch that still applies cleanly is not proof that it is semantically
correct for a newer GrapheneOS revision.** `git apply` only checks textual
context. Upstream may rename or move classes, change method signatures, change
settings-key semantics, alter SELinux attributes/neverallow rules, or change
Soong module types without touching the exact lines these patches modify.

Always re-review the resulting code, not just the exit status of `git apply`.

## Recommended workflow after an upstream update

1. Record the new base commits for each affected repository.
2. Run `scripts/check-upstream.sh --source /path/to/grapheneos-17` to see which
   recorded baselines have moved and whether the worktrees are dirty.
3. Create throwaway worktrees/checkouts at the new bases (do not touch the
   original worktrees). Test applicability with `git apply --check`.
4. For any patch that fails, inspect the rejected hunk manually and adapt the
   patch by hand. Do not blindly regenerate by copying the whole file.
5. Re-check the semantics against the current upstream:
   - `frameworks/base`: does `BatteryChargeLimit` / `Settings.Global` still
     have the expected shape? Does the SystemUI call sites still exist?
   - `packages/apps/Settings`: do `BoolSettingFragment`,
     `BatteryChargingOptimizationFragment`, and the Google feature provider
     still exist with compatible signatures?
   - `system/sepolicy`: is `sota_prop` still defined, and does
     `system_server` still have `set_prop` access? Watch for new
     `neverallow` rules.
   - `vendor/adevtool`: are the laguna platform `device.mk` /
     `BoardConfig-common.mk` include points unchanged? Does the vendor SELinux
     directory convention still hold?
6. Re-run the applicability + content checks and update
   `docs/patch-provenance.md` with the new base commits and results.
7. Only then rebuild.

## Notes specific to this feature

- The feature property is `sota.charge.limit`. Do **not** reintroduce the
  `sota.charge.stop.level` changes: they belong to an unrelated stock "zombie"
  init rule and are not used by this implementation.
- `vendor-specs/google_devices/blazer.yml` is an adevtool-generated vendor
  module spec. Do not hand-edit recorded checksums. If the vendor module must be
  regenerated, use `adevtool generate-all` deliberately and review the result —
  it can overwrite local edits.
