# Build baseline and provenance

## Device

- Product / device: `blazer` (Pixel 10 Pro), GrapheneOS 17 branch.
- Reported device fingerprint (not independently re-verified here):
  `google/blazer/blazer:17/CP2A.260805.005/2026091900:userdebug/test-keys`.

## Source workspace

- Path on the build host (T5810): `/home/nw/grapheneos-17` (a Repo workspace).
- Manifest project revision at capture time:
  `583aa9e3ac7dad13bf77bb26ac4f52784e763a52`.
- The fully resolved, revision-pinned manifest is stored at
  `manifest/baseline-manifest.xml` (generated with `repo manifest -r`, which
  does not sync or modify the source tree).

## Build configuration

- Lunch target: `blazer-cur-userdebug`.
- Required environment flag: `SKIP_CTS_API_COVERAGE=true`.
- Build command: `m`.

Values verified from `out/soong.log` (environment record of the build):

```text
TARGET_PRODUCT=blazer
TARGET_BUILD_VARIANT=userdebug
TARGET_RELEASE=cur
SKIP_CTS_API_COVERAGE=true
BUILD_ID_blazer=CP2A.260805.005
BUILD_NUMBER=2026091900
```

Additional values reported from the prior work (not independently re-derived in
this repository):

```text
BOARD_API_LEVEL=202604
BOARD_SEPOLICY_VERS=202604
PLATFORM_SEPOLICY_VERSION=202604
```

## Build result and evidence

The full build completed successfully. Evidence is present in the build host
`out/` directory (`out/verbose.log.gz`):

```text
status: ninja: 1h54m11.03s Build Succeeded: 49531 steps - 7.23/s
Build completed.
```

- Reported exit code: 0.
- Reported duration: ~1 hour 54 minutes (1h54m11.03s above).
- Successful Ninja summary: `49531 steps - 7.23/s`.

Build logs and binaries are intentionally **not** published here. They may
contain host paths and machine-specific data, and they are not needed to
reproduce the build.

## Affected repositories (base commits)

| Repository | Base commit (exact) |
| --- | --- |
| `frameworks/base` | `00b2ff99f28b9b5862514b0a25c265b51c59a8fb` |
| `packages/apps/Settings` | `749748aaef77cdd2a62cce7de0ee0db30a4efafa` |
| `system/sepolicy` | `e9cc3685467b6daffd331461c94a3b848164930a` |
| `vendor/adevtool` | `e3c17c023499102f7551fea8c7a936939edf514c` |

`build/soong` was present at `250710f7f87acfbb8e3c517d90abde8b4a08fe1e` during
the baseline, but its local workaround change is **out of scope** and is not
included in this repository.

## Out-of-scope build workarounds

The following changes existed in the build environment but are unrelated to the
feature and are deliberately excluded:

- `build/soong/test_suites/test_suites.go` `SKIP_CTS_API_COVERAGE` guard.
- `.bak` / `.disabled` `Android.bp` build workarounds across `cts`,
  `hardware/interfaces`, `device/generic/*`, `trusty/vendor/google/aosp`,
  `external/libese`, `external/openwrt-prebuilts`, and `platform_testing`.
- The `packages/modules/Connectivity` `EntitlementManager` hard-code.

## Device-test status

There is **no** physical-device validation record for the custom feature. The
helper binary was built, but no image from this work is known to have been
flashed or booted. Treat the feature as **build-validated only**.
