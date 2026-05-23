#!/usr/bin/env bash
# Create a new task in this kiro-workspace.
#
# Usage:
#   scripts/new-task.sh <task-name> [project-path]
#
# Example:
#   scripts/new-task.sh mindrag /home/sharp/MindRAG

set -euo pipefail

TASK_NAME="${1:-}"
PROJECT_PATH="${2:-/path/to/${TASK_NAME}}"

if [[ -z "$TASK_NAME" ]]; then
  echo "Usage: $0 <task-name> [project-path]" >&2
  exit 1
fi

# Resolve workspace root: directory containing .kiro/
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATE_DIR="$WORKSPACE_ROOT/.kiro/templates/task"

if [[ ! -d "$TEMPLATE_DIR" ]]; then
  echo "Template dir not found: $TEMPLATE_DIR" >&2
  exit 1
fi

TASK_DIR="$WORKSPACE_ROOT/tasks/$TASK_NAME"
AGENT_FILE="$WORKSPACE_ROOT/.kiro/agents/$TASK_NAME.json"
PROMPT_FILE="$WORKSPACE_ROOT/.kiro/prompts/$TASK_NAME.md"

if [[ -d "$TASK_DIR" ]]; then
  echo "Task already exists: $TASK_DIR" >&2
  exit 1
fi

DATE="$(date '+%Y-%m-%d')"

mkdir -p "$TASK_DIR" "$TASK_DIR/aidlc-docs"
mkdir -p "$WORKSPACE_ROOT/.kiro/agents" "$WORKSPACE_ROOT/.kiro/prompts"

substitute() {
  local src="$1" dst="$2"
  sed \
    -e "s|{{TASK_NAME}}|$TASK_NAME|g" \
    -e "s|{{PROJECT_PATH}}|$PROJECT_PATH|g" \
    -e "s|{{DATE}}|$DATE|g" \
    "$src" > "$dst"
}

substitute "$TEMPLATE_DIR/RESUME.md.tpl"   "$TASK_DIR/RESUME.md"
substitute "$TEMPLATE_DIR/WORKFLOW.md.tpl" "$TASK_DIR/WORKFLOW.md"
substitute "$TEMPLATE_DIR/learned.md.tpl"  "$TASK_DIR/learned.md"
substitute "$TEMPLATE_DIR/agent.json.tpl"  "$AGENT_FILE"
substitute "$TEMPLATE_DIR/prompt.md.tpl"   "$PROMPT_FILE"

cat <<EOF
✓ Created task '$TASK_NAME'
  - $TASK_DIR/RESUME.md
  - $TASK_DIR/WORKFLOW.md
  - $TASK_DIR/learned.md    (per-task knowledge pool; cross-task lessons go in .kiro/learned/LEARNED.md)
  - $TASK_DIR/aidlc-docs/   (gitignored, AI-DLC will write here)
  - $AGENT_FILE
  - $PROMPT_FILE

Next:
  1. Edit $PROMPT_FILE to refine the agent's role.
  2. Edit $TASK_DIR/RESUME.md with current state.
  3. Start working: kiro-cli chat --agent $TASK_NAME
EOF
