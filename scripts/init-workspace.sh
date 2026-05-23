#!/usr/bin/env bash
# Bootstrap a fresh fork of kiro-workspace-template.
#
# Idempotent: safe to re-run. Creates missing user-instance files from
# bundled .tpl skeletons. Existing files are never overwritten.
#
# Run once after cloning the template, and again whenever you add a task
# that pre-dates per-task learned.md (i.e. when upgrading an older
# workspace to the new memory-layering convention).
#
# Usage:
#   scripts/init-workspace.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$WORKSPACE_ROOT"

copy_if_missing() {
  local src="$1" dst="$2"
  if [[ -f "$dst" ]]; then
    echo "  · skip   $dst (already exists)"
  elif [[ -f "$src" ]]; then
    cp "$src" "$dst"
    echo "  + create $dst"
  else
    echo "  ! source missing: $src" >&2
    return 1
  fi
}

echo "==> Workspace-level files"
mkdir -p .kiro/shared .kiro/learned
copy_if_missing .kiro/shared/SHARED-CONTEXT.md.tpl  .kiro/shared/SHARED-CONTEXT.md
copy_if_missing .kiro/learned/LEARNED.md.tpl        .kiro/learned/LEARNED.md

echo
echo "==> Per-task learned.md (for any existing task missing it)"
TASK_TPL=".kiro/templates/task/learned.md.tpl"
if [[ ! -f "$TASK_TPL" ]]; then
  echo "  ! per-task template missing: $TASK_TPL (skipping)" >&2
else
  found_any=0
  for task_dir in tasks/*/; do
    [[ -d "$task_dir" ]] || continue
    task_name="$(basename "$task_dir")"
    [[ "$task_name" == "example" ]] && continue
    dst="${task_dir}learned.md"
    if [[ -f "$dst" ]]; then
      echo "  · skip   $dst"
    else
      sed "s|{{TASK_NAME}}|$task_name|g" "$TASK_TPL" > "$dst"
      echo "  + create $dst"
    fi
    found_any=1
  done
  [[ $found_any -eq 0 ]] && echo "  (no tasks/ entries yet — run scripts/new-task.sh to scaffold one)"
fi

echo
echo "Done. Next:"
echo "  - Edit .kiro/shared/SHARED-CONTEXT.md with your org/team/network facts"
echo "  - Read .kiro/skills/memory-layering.md to understand where learnings go"
