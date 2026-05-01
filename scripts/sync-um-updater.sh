#!/usr/bin/env bash
set -euo pipefail

# Downloads um-updater.php from the canonical private repo (pinned ref)
# and copies it into a plugin repo at includes/um-updater.php.
#
# Requires: gh CLI (authenticated with repo access)

UM_UPDATER_REF_DEFAULT="v4.0.0"
DEST_DEFAULT="includes/um-updater.php"

REF="${UM_UPDATER_REF:-$UM_UPDATER_REF_DEFAULT}"
DEST="${UM_UPDATER_DEST:-$DEST_DEFAULT}"

usage() {
  cat <<EOF
Usage: $(basename "$0") [--ref <tag|branch>] [--dest <path>]

Env vars:
  UM_UPDATER_REF   (default: ${UM_UPDATER_REF_DEFAULT})
  UM_UPDATER_DEST  (default: ${DEST_DEFAULT})

Examples:
  UM_UPDATER_REF=v4.0.0 $(basename "$0")
  $(basename "$0") --ref v4.0.0 --dest includes/um-updater.php
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --ref)
      REF="$2"; shift 2;;
    --dest)
      DEST="$2"; shift 2;;
    -h|--help)
      usage; exit 0;;
    *)
      echo "Unknown arg: $1" >&2
      usage
      exit 2;;
  esac
done

REPO="dontpressthis/um-updater"

TMP_FILE="$(mktemp)"
trap 'rm -f "$TMP_FILE"' EXIT

echo "Syncing um-updater from ${REPO}@${REF} -> ${DEST}" >&2

# Use gh CLI for private repo access (falls back to curl for public repos)
if command -v gh &>/dev/null; then
  gh api "repos/${REPO}/contents/um-updater.php?ref=${REF}" \
    --jq '.content' 2>/dev/null | base64 -d > "$TMP_FILE"
else
  URL="https://raw.githubusercontent.com/${REPO}/${REF}/um-updater.php"
  curl -fsSL "$URL" -o "$TMP_FILE"
fi

# Basic sanity checks.
if ! head -n 1 "$TMP_FILE" | grep -q "^<?php"; then
  echo "Downloaded file doesn't look like PHP (missing <?php). Ref=${REF}" >&2
  exit 1
fi

mkdir -p "$(dirname "$DEST")"
cp "$TMP_FILE" "$DEST"

echo "✓ Synced um-updater (${REF})" >&2
