#!/usr/bin/env bash
# Create a new task in this kiro-workspace.
#
# Usage:
#   scripts/new-task.sh [--no-aidlc] <task-name> [project-path]
#
# Flags:
#   --no-aidlc   Skip the AI-DLC input templates (vision.md, tech-env.md).
#                Use for simple tasks that won't go through inception.
#
# Examples:
#   scripts/new-task.sh mindrag /home/sharp/MindRAG
#   scripts/new-task.sh --no-aidlc adhoc-script /tmp/scratch

set -euo pipefail

NO_AIDLC=0
POSITIONAL=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-aidlc) NO_AIDLC=1; shift ;;
    --help|-h)
      sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    -*)
      echo "Unknown flag: $1" >&2
      exit 1
      ;;
    *)
      POSITIONAL+=("$1"); shift
      ;;
  esac
done

TASK_NAME="${POSITIONAL[0]:-}"
PROJECT_PATH="${POSITIONAL[1]:-/path/to/${TASK_NAME}}"

if [[ -z "$TASK_NAME" ]]; then
  echo "Usage: $0 [--no-aidlc] <task-name> [project-path]" >&2
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

substitute "$TEMPLATE_DIR/task.yaml.tpl"   "$TASK_DIR/task.yaml"
substitute "$TEMPLATE_DIR/RESUME.md.tpl"   "$TASK_DIR/RESUME.md"
substitute "$TEMPLATE_DIR/WORKFLOW.md.tpl" "$TASK_DIR/WORKFLOW.md"
substitute "$TEMPLATE_DIR/learned.md.tpl"  "$TASK_DIR/learned.md"
substitute "$TEMPLATE_DIR/agent.json.tpl"  "$AGENT_FILE"
substitute "$TEMPLATE_DIR/prompt.md.tpl"   "$PROMPT_FILE"

INPUTS_TPL="$WORKSPACE_ROOT/.kiro/templates/inputs"
AIDLC_INPUTS_LINE=""
if [[ $NO_AIDLC -eq 0 ]]; then
  if [[ -f "$INPUTS_TPL/vision.md.tpl" && -f "$INPUTS_TPL/tech-env.md.tpl" ]]; then
    substitute "$INPUTS_TPL/vision.md.tpl"   "$TASK_DIR/vision.md"
    substitute "$INPUTS_TPL/tech-env.md.tpl" "$TASK_DIR/tech-env.md"
    AIDLC_INPUTS_LINE="
  - $TASK_DIR/vision.md     (AI-DLC input — fill before inception, see vision-document-guide.md)
  - $TASK_DIR/tech-env.md   (AI-DLC input — fill before inception, see technical-environment-guide.md)"
  else
    echo "Warning: AI-DLC input templates missing under $INPUTS_TPL — skipping vision.md / tech-env.md" >&2
  fi
fi

cat <<EOF
✓ Created task '$TASK_NAME'
  - $TASK_DIR/task.yaml     (structured metadata — single source of truth for paths/repo)
  - $TASK_DIR/RESUME.md
  - $TASK_DIR/WORKFLOW.md
  - $TASK_DIR/learned.md    (per-task knowledge pool; cross-task lessons go in .kiro/learned/LEARNED.md)$AIDLC_INPUTS_LINE
  - $TASK_DIR/aidlc-docs/   (gitignored, AI-DLC will write here)
  - $AGENT_FILE
  - $PROMPT_FILE

Next:
  1. Edit $PROMPT_FILE to refine the agent's role.
  2. Edit $TASK_DIR/RESUME.md with current state.
  3. Start working: kiro-cli chat --agent $TASK_NAME
EOF
