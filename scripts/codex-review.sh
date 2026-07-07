#!/usr/bin/env bash
# codex-review.sh — use the OpenAI Codex CLI as an INDEPENDENT second opinion on
# a code change, before committing.
#
# Why this exists (see .kiro/adr/0002-review-outsourced-to-codex.md):
#   The Layer C `code-quality-reviewer` agent (.kiro/steering/code-quality.md) is
#   a kiro subagent — same model family, same runtime. Same-model review has a
#   self-consistency blind spot. Codex is a DIFFERENT model with NO knowledge of
#   this session's context, so it catches what the primary model rationalizes as
#   correct. It complements Layer C, it does not replace it: Layer C runs
#   per-unit mid-construction on the four semantic classes; codex runs at
#   commit time over the whole change.
#
# Division of labor:
#   - Tests are run by the primary agent (pytest / tsc --noEmit / build) — the
#     fast gate, not outsourced.
#   - Review is outsourced to codex (independent model), run before every commit.
#
# Usage:
#   codex-review.sh <repo_dir> [codex-review-args...]
# On Windows, do NOT call this via bare `bash` — inside a kiro agent that
# resolves to a broken WSL bash. Use the launcher instead:
#   pwsh -ExecutionPolicy Bypass -File scripts/codex-review.ps1 <repo_dir>
# Default scope = --uncommitted (review staged/unstaged/untracked before commit).
# Any other scope is passed straight through to `codex review`, e.g.:
#   codex-review.sh <repo> --commit HEAD      # review the latest commit
#   codex-review.sh <repo> --base main        # review the diff against main
#   codex-review.sh <repo> "focus on the write-path safety"   # custom focus prompt
#
# Conventions:
#   - Do NOT hard-code --model: use codex's configured default (latest) model.
#     (A reference impl that pinned a version number is a trap — models update.)
#   - `codex review` is read-only analysis; it does not run project code, so no
#     sandbox loosening is needed.
#   - Auth is codex's own (ChatGPT / API key); this script does not manage it.
set -uo pipefail

REPO="${1:-}"
if [ -z "$REPO" ]; then
  echo "usage: codex-review.sh <repo_dir> [codex review args...]" >&2
  exit 2
fi
shift || true

# Default to reviewing uncommitted changes; pass through any caller-supplied scope/prompt.
ARGS=("$@")
if [ ${#ARGS[@]} -eq 0 ]; then
  ARGS=(--uncommitted)
fi

if ! command -v codex >/dev/null 2>&1; then
  echo "ERROR: codex CLI not found (which codex failed). Install it or check PATH." >&2
  exit 3
fi

if [ ! -d "$REPO" ]; then
  echo "ERROR: repo directory does not exist: $REPO" >&2
  exit 2
fi

cd "$REPO" || { echo "ERROR: cannot enter repo: $REPO" >&2; exit 2; }

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "ERROR: $REPO is not a git repo (codex review needs a git diff)." >&2
  exit 2
fi

echo "[codex-review] repo=$REPO  args=${ARGS[*]}" >&2
echo "[codex-review] using codex default model (not pinned). review=read-only, no file edits." >&2
echo "----------------------------------------------------------------" >&2

# Use `codex exec review` (non-interactive exec family), NOT the top-level
# `codex review`: the top-level command renders a TUI whose result can't be
# captured through a pipe; `exec review` prints the review cleanly to stdout so
# the calling agent can read it and triage.
codex exec review "${ARGS[@]}"
rc=$?

echo "----------------------------------------------------------------" >&2
if [ $rc -ne 0 ]; then
  echo "[codex-review] codex exited $rc (see output above)." >&2
fi
exit $rc
