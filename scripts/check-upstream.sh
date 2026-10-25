#!/usr/bin/env bash
# check-upstream.sh -- READ-ONLY status reporter.
# Reports manifest/project revisions and dirtiness. Never syncs, never writes
# to the source workspace, and never changes Git state.
set -euo pipefail

SRC=""
while [ $# -gt 0 ]; do
  case "$1" in
    --source) SRC="${2:-}"; shift 2 ;;
    -h|--help) echo "usage: $(basename "$0") --source /path/to/grapheneos-17"; exit 0 ;;
    *) echo "error: unknown argument: $1" >&2; exit 2 ;;
  esac
done
if [ -z "$SRC" ]; then echo "error: --source is required" >&2; exit 2; fi
if [ ! -d "$SRC/.repo" ]; then echo "error: $SRC is not a Repo workspace (no .repo directory)" >&2; exit 2; fi

BASELINE_MANIFEST="583aa9e3ac7dad13bf77bb26ac4f52784e763a52"
PROJECTS=(frameworks/base packages/apps/Settings system/sepolicy vendor/adevtool)
declare -A BASELINE=(
  [frameworks/base]="00b2ff99f28b9b5862514b0a25c265b51c59a8fb"
  [packages/apps/Settings]="749748aaef77cdd2a62cce7de0ee0db30a4efafa"
  [system/sepolicy]="e9cc3685467b6daffd331461c94a3b848164930a"
  [vendor/adevtool]="e3c17c023499102f7551fea8c7a936939edf514c"
)

echo "==============================================================================="
echo "GrapheneOS charge-limit upstream status (read-only)"
echo "Workspace: $SRC"
echo "==============================================================================="

mrev="$(git -C "$SRC/.repo/manifests" rev-parse HEAD 2>/dev/null || echo unknown)"
echo "Manifest revision : $mrev"
if [ "$mrev" = "$BASELINE_MANIFEST" ]; then
  echo "                  matches recorded baseline"
else
  echo "                  DIFFERS from recorded baseline ($BASELINE_MANIFEST)"
fi
echo

for proj in "${PROJECTS[@]}"; do
  dir="$SRC/$proj"
  echo "--- $proj"
  if [ ! -d "$dir/.git" ] && [ ! -e "$dir/.git" ]; then
    echo "    MISSING or not a git repository"
    continue
  fi
  head="$(git -C "$dir" rev-parse HEAD 2>/dev/null || echo unknown)"
  echo "    HEAD            : $head"
  if [ "${BASELINE[$proj]:-}" = "$head" ]; then
    echo "    baseline        : matches"
  else
    echo "    baseline        : CHANGED (recorded ${BASELINE[$proj]:-none})"
  fi
  dirty="$(git -C "$dir" status --porcelain 2>/dev/null || true)"
  if [ -z "$dirty" ]; then
    echo "    worktree        : clean"
  else
    echo "    worktree        : DIRTY / UNTRACKED"
    printf "%s\n" "$dirty" | sed "s/^/        /"
  fi
  stashes="$(git -C "$dir" stash list 2>/dev/null || true)"
  if [ -n "$stashes" ]; then
    echo "    stashes         : present (left untouched)"
    printf "%s\n" "$stashes" | sed "s/^/        /"
  fi
  echo
done

echo "No files were modified. This script is read-only."
