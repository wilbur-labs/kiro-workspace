#!/usr/bin/env bash
# Bootstrap a fresh fork of kiro-workspace.
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
echo "==> Per-task files (for any existing task missing them)"
LEARNED_TPL=".kiro/templates/task/learned.md.tpl"
CR_TPL=".kiro/templates/task/change-requests.md.tpl"

instantiate_per_task() {
  local src_tpl="$1" rel_dst="$2" task_dir="$3" task_name="$4"
  if [[ ! -f "$src_tpl" ]]; then return 0; fi
  local dst="${task_dir}${rel_dst}"
  local dst_parent
  dst_parent="$(dirname "$dst")"
  mkdir -p "$dst_parent"
  if [[ -f "$dst" ]]; then
    echo "  · skip   $dst"
  else
    sed "s|{{TASK_NAME}}|$task_name|g" "$src_tpl" > "$dst"
    echo "  + create $dst"
  fi
}

found_any=0
for task_dir in tasks/*/; do
  [[ -d "$task_dir" ]] || continue
  task_name="$(basename "$task_dir")"
  [[ "$task_name" == "example" ]] && continue
  instantiate_per_task "$LEARNED_TPL" "learned.md"                    "$task_dir" "$task_name"
  instantiate_per_task "$CR_TPL"      "aidlc-docs/change-requests.md" "$task_dir" "$task_name"
  found_any=1
done
[[ $found_any -eq 0 ]] && echo "  (no tasks/ entries yet — run scripts/new-task.sh to scaffold one)"

echo
echo "Done. Next:"
echo "  - Edit .kiro/shared/SHARED-CONTEXT.md with your org/team/network facts"
echo "  - Read .kiro/skills/memory-layering.md to understand where learnings go"
