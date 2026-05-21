#!/usr/bin/env bash
# Update AI-DLC rules from the latest GitHub release.
#
# Usage:
#   scripts/update-aidlc.sh [version]
#
# Examples:
#   scripts/update-aidlc.sh          # latest release
#   scripts/update-aidlc.sh v0.1.8   # specific version

set -euo pipefail

VERSION="${1:-}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TMP_DIR="$(mktemp -d)"

cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

# Resolve download URL
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

# Find extracted aidlc-rules directory
RULES_DIR="$TMP_DIR/aidlc-rules"
if [[ ! -d "$RULES_DIR" ]]; then
  echo "Error: Expected aidlc-rules/ in zip but not found." >&2
  exit 1
fi

# Update steering rules
echo "Updating .kiro/steering/aws-aidlc-rules/..."
rm -rf "$WORKSPACE_ROOT/.kiro/steering/aws-aidlc-rules"
cp -R "$RULES_DIR/aws-aidlc-rules" "$WORKSPACE_ROOT/.kiro/steering/"

# Update rule details
echo "Updating .kiro/aws-aidlc-rule-details/..."
rm -rf "$WORKSPACE_ROOT/.kiro/aws-aidlc-rule-details"
cp -R "$RULES_DIR/aws-aidlc-rule-details" "$WORKSPACE_ROOT/.kiro/"

# Update VERSION
if [[ -f "$RULES_DIR/VERSION" ]]; then
  cp "$RULES_DIR/VERSION" "$WORKSPACE_ROOT/.kiro/VERSION"
  echo "Version: $(cat "$WORKSPACE_ROOT/.kiro/VERSION")"
fi

echo "✓ AI-DLC rules updated successfully."
