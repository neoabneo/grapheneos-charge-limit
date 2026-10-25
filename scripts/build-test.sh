#!/usr/bin/env bash
# build-test.sh -- documented build driver for the charge-limit feature.
#
# By default this only PRINTS the commands. With --run it executes them after
# an interactive confirmation. It never flashes a device and never runs
# repo sync / git reset / git clean.
set -euo pipefail

SRC=""
RUN=0
while [ $# -gt 0 ]; do
  case "$1" in
    --source) SRC="${2:-}"; shift 2 ;;
    --run) RUN=1; shift ;;
    -h|--help)
      echo "usage: $(basename "$0") --source /path/to/grapheneos-17 [--run]"
      exit 0 ;;
    *) echo "error: unknown argument: $1" >&2; exit 2 ;;
  esac
done

if [ -z "$SRC" ]; then echo "error: --source is required" >&2; exit 2; fi
if [ ! -d "$SRC/.repo" ]; then echo "error: $SRC is not a Repo workspace (no .repo directory)" >&2; exit 2; fi

cat <<INFO
===============================================================================
Build plan for the charge-limit feature (blazer / Pixel 10 Pro)
===============================================================================
Workspace : $SRC
Lunch     : blazer-cur-userdebug
Env       : SKIP_CTS_API_COVERAGE=true
Command   : m
------------------------------------------------------------------------------
Equivalent shell:

  cd "$SRC"
  source build/envsetup.sh
  lunch blazer-cur-userdebug
  export SKIP_CTS_API_COVERAGE=true
  m

Notes:
  * A full build takes roughly two hours and a lot of disk.
  * This does NOT flash a device.
  * This does NOT sync/reset/clean the workspace.
  * It assumes the feature patches have already been applied.
  * See docs/build.md and docs/baseline.md.
===============================================================================
INFO

if [ "$RUN" -eq 0 ]; then
  echo "Dry run only. Re-run with --run to build (you will be asked to confirm)."
  exit 0
fi

printf "Type BUILD to start the build: "
read -r reply
if [ "$reply" != "BUILD" ]; then
  echo "Aborted by operator."
  exit 1
fi

cd "$SRC"
# shellcheck disable=SC1091
source build/envsetup.sh
lunch blazer-cur-userdebug
export SKIP_CTS_API_COVERAGE=true
m
echo "Build finished. This script did not flash anything."
