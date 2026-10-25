# Patch provenance

All patches are plain unified diffs applied with `git apply -p1` from the root
of the target repository. Applicability was tested **without touching the
original source tree**, by cloning each repository locally (object-sharing,
`--no-checkout`), resetting the index to the recorded base commit, and running
`git apply --check --cached`. After applying, the resulting blob contents were
compared byte-for-byte (SHA-256) against the reviewed working-tree files.

## Summary

| Patch | Target repo | Base commit | Files | Applicability | Content match |
| --- | --- | --- | --- | --- | --- |
| `patches/frameworks-base/frameworks-base.patch` | `frameworks/base` | `00b2ff99f28b9b5862514b0a25c265b51c59a8fb` | 5 modified | clean at base | exact |
| `patches/packages-apps-Settings/settings-app.patch` | `packages/apps/Settings` | `749748aaef77cdd2a62cce7de0ee0db30a4efafa` | 5 modified + 2 new | clean at base | exact |
| `patches/system-sepolicy/system-sepolicy.patch` | `system/sepolicy` | `e9cc3685467b6daffd331461c94a3b848164930a` | 2 modified | clean at base | exact |
| `patches/vendor-adevtool/vendor-adevtool.patch` | `vendor/adevtool` | `e3c17c023499102f7551fea8c7a936939edf514c` | 2 modified + 5 new | clean at base | exact |

Patch SHA-256:

```text
390988b4baa21f16e773ec733fd9b8f3d9b74c7df0b6a7410c94d1a91204b41b  frameworks-base.patch
790c770178a3d6a0986c7bf0ef5df761ed5bbc9c5e9ec4457cad23cb235ead37  settings-app.patch
bc01ed488dd6e541210d8860196e4f8811568d6ee9504aa1ef62b9d5fc233159  system-sepolicy.patch
a05a44875913d59d8761ccb24031ef4f107dd5857d688ae11fc33c29ba79046b  vendor-adevtool.patch
```

## Details

### `frameworks/base`

- Files: `core/java/android/ext/power/BatteryChargeLimit.java`,
  `core/java/android/provider/Settings.java`,
  `packages/SystemUI/src/com/android/systemui/statusbar/KeyguardIndicationController.java`,
  `packages/SystemUI/src/com/google/android/systemui/statusbar/policy/BatteryControllerImplGoogle.java`,
  `services/core/java/com/android/server/BatteryService.java`.
- Adds `BatteryChargeLimit.{MIN_LEVEL,MAX_LEVEL,DEFAULT_LEVEL,HYSTERESIS}`,
  `getChargeLimit()`/`getChargeStartLevel()`, `IntSetting` + the new
  `Settings.Global.BATTERY_CHARGE_LIMIT_LEVEL` key, dynamic value use in
  SystemUI/Keyguard, and a `BatteryService` observer that publishes
  `sota.charge.limit`.
- No new files. No unrelated changes.

### `packages/apps/Settings`

- Modified: `res/values/strings_ext.xml`,
  `src/com/android/settings/ext/BoolSettingFragment.java`,
  `src/com/android/settings/fuelgauge/BatteryChargingOptimizationFragment.java`,
  `src/com/android/settings/fuelgauge/BatteryChargingOptimizationPrefController.java`,
  `src/com/google/android/settings/fuelgauge/BatterySettingsFeatureProviderGoogleImpl.java`.
- New: `res/layout/preference_charge_limit_switch.xml`,
  `src/com/android/settings/fuelgauge/ChargeLimitSwitchPreference.java`.
- The new preference resource and Java class are **required** by the feature and
  are included as `new file mode` sections. (The upstream tracked-file diff
  alone is not sufficient.)

### `system/sepolicy`

- Files: `private/property_contexts`, `private/system_server.te`.
- Adds `sota.charge.limit u:object_r:sota_prop:s0 exact int` and
  `set_prop(system_server, sota_prop)` — the access policy required for
  `BatteryService` to set the property.

### `vendor/adevtool`

- Modified: `config/mk/google_devices/platform/laguna/BoardConfig-common.mk`
  (adds `BOARD_VENDOR_SEPOLICY_DIRS += .../sepolicy/vendor`),
  `config/mk/google_devices/platform/laguna/device.mk`
  (adds `PRODUCT_PACKAGES += gos-charge-limit`).
- New: `config/mk/google_devices/platform/laguna/gos-charge-limit/Android.bp`,
  `.../gos-charge-limit/gos-charge-limit.rc`,
  `.../gos-charge-limit/src/main.rs`,
  `config/mk/google_devices/platform/laguna/sepolicy/vendor/file_contexts`,
  `config/mk/google_devices/platform/laguna/sepolicy/vendor/gos_charge_limit.te`.
- The helper validates 50–80, applies a 3-point hysteresis, and writes
  `charge_start_level` and `charge_stop_level` under
  `/sys/devices/platform/google,charger/`.

#### Deliberately excluded hunks (vendor/adevtool)

The prior in-tree change also touched three things that are **not** part of the
feature and are omitted here:

1. `config/device/common/sysprop-exclusion.yml`: removal of the upstream
   exclusion `- sota.charge.stop.level`. The current implementation uses
   `sota.charge.limit`; nothing sets `sota.charge.stop.level`. The upstream
   exclusion is preserved.
2. `vendor-skels/google_devices/blazer/sepolicy/system_ext/private/property_contexts`:
   an added `sota.charge.stop.level` label. Per `vendor-skels/README.md`, those
   files are history records and are **not used for vendor module generation**.
3. `vendor-specs/google_devices/blazer.yml`: a recorded `property_contexts`
   checksum. Its provenance is tied to the obsolete property change and could
   not be confidently separated from it, so it is **omitted**. This file is
   consumed by adevtool generation (not by a normal build); if the vendor module
   is ever regenerated, refresh it with `adevtool generate-all --update-spec`
   rather than hand-editing.

If a future maintainer decides the vendor module spec must be refreshed, that is
an adevtool step, not part of applying this patch set.

## Excluded, unrelated work

None of the following are included in any patch:

- `build/soong/test_suites/test_suites.go`.
- `.bak` / `.disabled` `Android.bp` workarounds.
- `packages/modules/Connectivity` `EntitlementManager` hard-code.
- Changes under `cts`, `hardware/interfaces`, `device/generic/*`,
  `trusty/vendor/google/aosp`, `external/libese`,
  `external/openwrt-prebuilts`, `platform_testing`, or
  `system/software_defined_vehicle/*`.
