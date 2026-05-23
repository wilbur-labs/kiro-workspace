#!/usr/bin/env bash
# Update AI-DLC rules from the latest GitHub release.
#
# By default, refuses to clobber local modifications under
# .kiro/aws-aidlc-rule-details/. Use --dry-run to preview the update,
# --force to override the local-modification check, and rely on the
# automatic backup at .kiro/.aidlc-backup-<timestamp>/ to recover.
#
# Usage:
#   scripts/update-aidlc.sh [--dry-run] [--force] [version]
#
# Examples:
#   scripts/update-aidlc.sh                   # latest release, refuses if local mods
#   scripts/update-aidlc.sh --dry-run         # preview changes only
#   scripts/update-aidlc.sh v0.1.8            # specific version
#   scripts/update-aidlc.sh --force v0.1.9    # overwrite even with local mods

set -euo pipefail

DRY_RUN=0
FORCE=0
VERSION=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --force)   FORCE=1;   shift ;;
    --help|-h)
      sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    -*)
      echo "Unknown flag: $1" >&2
      exit 1
      ;;
    *)
      if [[ -n "$VERSION" ]]; then
        echo "Unexpected extra argument: $1" >&2
        exit 1
      fi
      VERSION="$1"
      shift
      ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TMP_DIR="$(mktemp -d)"

cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

# --- 1. Resolve and download release ---

if [[ -z "$VERSION" ]]; then
  echo "Fetching latest release info..."
  DOWNLOAD_URL=$(curl -sL https://api.github.com/repos/awslabs/aidlc-workflows/releases/latest \
    | grep -o '"browser_download_url": *"[^"]*"' \
    | head -1 \
    | cut -d'"' -f4)
else
  echo "Fetching release $VERSION..."
  DOWNLOAD_URL=$(curl -sL "https://api.github.com/repos/awslabs/aidlc-workflows/releases/tags/$VERSION" \
    | grep -o '"browser_download_url": *"[^"]*"' \
    | head -1 \
    | cut -d'"' -f4)
fi

if [[ -z "$DOWNLOAD_URL" ]]; then
  echo "Error: Could not find release download URL." >&2
  exit 1
fi

echo "Downloading: $DOWNLOAD_URL"
curl -sL "$DOWNLOAD_URL" -o "$TMP_DIR/aidlc-rules.zip"
unzip -qo "$TMP_DIR/aidlc-rules.zip" -d "$TMP_DIR"

RULES_DIR="$TMP_DIR/aidlc-rules"
if [[ ! -d "$RULES_DIR" ]]; then
  echo "Error: Expected aidlc-rules/ in zip but not found." >&2
  exit 1
fi

# --- 2. Detect local modifications under aws-aidlc-rule-details/ ---
# The upstream zip is the authoritative pristine snapshot for the target version.
# If diff vs local rule-details is non-empty, the user has hand-edited rules
# (or is upgrading across versions, which also shows as diff). Refuse unless --force.

LOCAL_DETAILS="$WORKSPACE_ROOT/.kiro/aws-aidlc-rule-details"
UPSTREAM_DETAILS="$RULES_DIR/aws-aidlc-rule-details"

HAS_LOCAL_MODS=0
DIFF_OUTPUT=""
if [[ -d "$LOCAL_DETAILS" && -d "$UPSTREAM_DETAILS" ]]; then
  if ! DIFF_OUTPUT="$(diff -rq "$LOCAL_DETAILS" "$UPSTREAM_DETAILS" 2>&1)"; then
    HAS_LOCAL_MODS=1
  fi
fi

# --- 3. List files that will change ---

list_changes() {
  echo
  echo "=== Files that will be replaced ==="
  echo
  echo "  .kiro/steering/aws-aidlc-rules/      (will be rm -rf and recreated from upstream)"
  echo "  .kiro/aws-aidlc-rule-details/        (will be rm -rf and recreated from upstream)"
  if [[ -f "$RULES_DIR/VERSION" ]]; then
    local new_ver
    new_ver="$(cat "$RULES_DIR/VERSION")"
    local cur_ver="(none)"
    [[ -f "$WORKSPACE_ROOT/.kiro/VERSION" ]] && cur_ver="$(cat "$WORKSPACE_ROOT/.kiro/VERSION")"
    echo "  .kiro/VERSION                        ($cur_ver  ->  $new_ver)"
  fi
  if [[ $HAS_LOCAL_MODS -eq 1 ]]; then
    echo
    echo "=== Detected diff vs upstream under .kiro/aws-aidlc-rule-details/ ==="
    echo "    (either local hand-edits or a version upgrade — both will be discarded unless --force is used)"
    echo
    printf '%s\n' "$DIFF_OUTPUT" | sed 's/^/    /'
  fi
}

if [[ $DRY_RUN -eq 1 ]]; then
  list_changes
  echo
  echo "Dry-run only — no files modified."
  exit 0
fi

# --- 4. Refuse if local mods present and not forced ---

if [[ $HAS_LOCAL_MODS -eq 1 && $FORCE -eq 0 ]]; then
  list_changes
  echo
  echo "Refusing to overwrite local modifications under .kiro/aws-aidlc-rule-details/."
  echo "Options:"
  echo "  1) Move your edits to .kiro/steering/<own-files>.md (the durable override layer)"
  echo "     and re-run without --force."
  echo "  2) Re-run with --force to discard local changes (a timestamped backup will be"
  echo "     created under .kiro/.aidlc-backup-<ts>/)."
  echo "  3) Run with --dry-run to inspect the diff first."
  exit 2
fi

# --- 5. Backup before destructive copy ---

TIMESTAMP="$(date '+%Y%m%d-%H%M%S')"
BACKUP_DIR="$WORKSPACE_ROOT/.kiro/.aidlc-backup-$TIMESTAMP"
mkdir -p "$BACKUP_DIR"

backup_if_exists() {
  local src="$1"
  if [[ -e "$src" ]]; then
    cp -R "$src" "$BACKUP_DIR/"
  fi
}

backup_if_exists "$WORKSPACE_ROOT/.kiro/steering/aws-aidlc-rules"
backup_if_exists "$WORKSPACE_ROOT/.kiro/aws-aidlc-rule-details"
backup_if_exists "$WORKSPACE_ROOT/.kiro/VERSION"

echo "Backed up current rules to: $BACKUP_DIR"

# --- 6. Apply update ---

echo "Updating .kiro/steering/aws-aidlc-rules/..."
rm -rf "$WORKSPACE_ROOT/.kiro/steering/aws-aidlc-rules"
cp -R "$RULES_DIR/aws-aidlc-rules" "$WORKSPACE_ROOT/.kiro/steering/"

echo "Updating .kiro/aws-aidlc-rule-details/..."
rm -rf "$WORKSPACE_ROOT/.kiro/aws-aidlc-rule-details"
cp -R "$RULES_DIR/aws-aidlc-rule-details" "$WORKSPACE_ROOT/.kiro/"

if [[ -f "$RULES_DIR/VERSION" ]]; then
  cp "$RULES_DIR/VERSION" "$WORKSPACE_ROOT/.kiro/VERSION"
  echo "Version: $(cat "$WORKSPACE_ROOT/.kiro/VERSION")"
fi

echo
echo "✓ AI-DLC rules updated successfully."
echo "  Backup retained at: $BACKUP_DIR"
echo "  Delete it once you've verified the upgrade works."
