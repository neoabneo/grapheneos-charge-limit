# Building and verifying

These commands are for the **GrapheneOS source workspace** (a Repo workspace,
e.g. `/home/nw/grapheneos-17`), not for this repository. They are documented
for reproducibility and are wrapped by `scripts/build-test.sh`.

## Environment

```sh
cd /path/to/grapheneos-17
source build/envsetup.sh
lunch blazer-cur-userdebug
export SKIP_CTS_API_COVERAGE=true
```

## Build

```sh
m
```

A full build of this baseline was reported to succeed with
`Build Succeeded: 49531 steps` (~1 h 54 m); see `docs/baseline.md` for the
evidence and the build configuration.

## Build-environment workaround (not part of the feature)

At the time of the baseline, `build/soong/test_suites/test_suites.go` contained
a local change:

```diff
-        if suite.Name == "cts" {
+        if suite.Name == "cts" && ctx.Config().Getenv("SKIP_CTS_API_COVERAGE") != "true" {
```

This is a **build-environment concern**, not a charge-limit feature change, and
it is **not** included in any patch here. It is recorded for completeness only.
Do not add it to the feature patch set.

## Hard rules for building

- Do **not** run `repo sync`, `git reset`, `git clean`, or `git stash pop`
  against a workspace whose state you care about.
- Do **not** run `adevtool generate-all`; it can overwrite intentionally edited
  generated files.
- Do **not** flash a device as part of a build check. Building an image is not
  the same as validating it on hardware.
- Preserve any pre-existing guard-file backups before temporary bypasses, and
  restore them afterwards.

## What a successful build proves

A successful build proves that the tree compiles and links. It does **not**
prove the feature works at runtime, that SELinux policy was regenerated from the
current inputs, or that any image was installed. Physical-device validation is
out of scope for this repository.
