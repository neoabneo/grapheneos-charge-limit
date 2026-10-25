#!/usr/bin/env bash
# apply-patches.sh -- cautiously apply the feature patches to a GrapheneOS tree.
#
# Default mode is DRY-RUN (report only). Nothing is modified unless --apply is
# given AND the operator confirms interactively.
#
# Safety guarantees:
#   * Refuses to run if any target worktree is dirty or has untracked files.
#   * Verifies each recorded base commit before doing anything.
#   * Verifies patch applicability with `git apply --check`.
#   * Never runs reset / clean / stash / checkout / commit.
#   * Never auto-resolves conflicts.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(dirname "$SCRIPT_DIR")"

SRC=""
APPLY=0
ONLY=""
while [ $# -gt 0 ]; do
  case "$1" in
    --source) SRC="${2:-}"; shift 2 ;;
    --apply) APPLY=1; shift ;;
    --only) ONLY="${2:-}"; shift 2 ;;
    -h|--help)
      cat <<USAGE
usage: $(basename "$0") --source /path/to/grapheneos-17 [--apply] [--only <project>]

  --source PATH   GrapheneOS Repo workspace (required)
  --apply         actually apply (default: dry-run report only)
  --only PROJECT  limit to one project (e.g. frameworks/base)
USAGE
      exit 0 ;;
    *) echo "error: unknown argument: $1" >&2; exit 2 ;;
  esac
done

if [ -z "$SRC" ]; then echo "error: --source is required" >&2; exit 2; fi
if [ ! -d "$SRC/.repo" ]; then echo "error: $SRC is not a Repo workspace (no .repo directory)" >&2; exit 2; fi

PROJECTS=(frameworks/base packages/apps/Settings system/sepolicy vendor/adevtool)
declare -A BASELINE=(
  [frameworks/base]="00b2ff99f28b9b5862514b0a25c265b51c59a8fb"
  [packages/apps/Settings]="749748aaef77cdd2a62cce7de0ee0db30a4efafa"
  [system/sepolicy]="e9cc3685467b6daffd331461c94a3b848164930a"
  [vendor/adevtool]="e3c17c023499102f7551fea8c7a936939edf514c"
)
declare -A PATCH=(
  [frameworks/base]="$ROOT/patches/frameworks-base/frameworks-base.patch"
  [packages/apps/Settings]="$ROOT/patches/packages-apps-Settings/settings-app.patch"
  [system/sepolicy]="$ROOT/patches/system-sepolicy/system-sepolicy.patch"
  [vendor/adevtool]="$ROOT/patches/vendor-adevtool/vendor-adevtool.patch"
)

if [ "$APPLY" -eq 1 ]; then MODE="APPLY"; else MODE="DRY-RUN (no changes)"; fi
echo "==============================================================================="
echo "charge-limit patch application"
echo "Workspace: $SRC"
echo "Mode     : $MODE"
echo "==============================================================================="
echo

problems=0
selected=()
for proj in "${PROJECTS[@]}"; do
  [ -n "$ONLY" ] && [ "$ONLY" != "$proj" ] && continue
  selected+=("$proj")
  dir="$SRC/$proj"
  patch="${PATCH[$proj]}"
  echo "--- $proj"

  if [ ! -e "$dir/.git" ]; then
    echo "    [FAIL] not a git repository"; problems=$((problems+1)); continue
  fi
  if [ ! -f "$patch" ]; then
    echo "    [FAIL] patch missing: $patch"; problems=$((problems+1)); continue
  fi

  if [ -n "$(git -C "$dir" status --porcelain)" ]; then
    echo "    [FAIL] worktree is dirty or has untracked files; refusing to touch it"
    git -C "$dir" status --porcelain | sed "s/^/           /"
    problems=$((problems+1)); continue
  fi
  echo "    worktree clean"

  head="$(git -C "$dir" rev-parse HEAD)"
  if [ "$head" != "${BASELINE[$proj]}" ]; then
    echo "    [FAIL] HEAD $head != expected base ${BASELINE[$proj]}"; problems=$((problems+1)); continue
  fi
  echo "    base commit matches"

  if git -C "$dir" apply --check -p1 "$patch"; then
    echo "    [ OK ] patch applies cleanly"
  else
    echo "    [FAIL] patch does not apply"; problems=$((problems+1)); continue
  fi
  echo
done

if [ "$problems" -ne 0 ]; then
  echo "Aborting: $problems check(s) failed. No changes made."
  exit 1
fi

if [ "$APPLY" -eq 0 ]; then
  echo "Dry-run complete. All checks passed. Re-run with --apply to modify the tree."
  exit 0
fi

echo "The following repositories will be MODIFIED: ${selected[*]}"
echo "This script will NOT commit, reset, clean, or stash anything."
printf "Type YES to proceed: "
read -r reply
if [ "$reply" != "YES" ]; then
  echo "Aborted by operator. No changes made."
  exit 1
fi

for proj in "${selected[@]}"; do
  dir="$SRC/$proj"; patch="${PATCH[$proj]}"
  echo "Applying $proj ..."
  git -C "$dir" apply -p1 "$patch"
  echo "  -> now:"; git -C "$dir" status --short | sed "s/^/     /"
done
echo
echo "Done. Review the changes and commit them yourself. Nothing was committed."
