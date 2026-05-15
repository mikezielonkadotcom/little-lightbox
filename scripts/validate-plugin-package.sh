#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

ZIP_PATH=""

usage() {
  cat <<EOF
Usage: $(basename "$0") [--zip <path>]

Validates plugin source headers, PHP syntax, bundled Update Machine updater,
readme version parity, and optional release ZIP contents.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --zip)
      ZIP_PATH="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown arg: $1" >&2
      usage
      exit 2
      ;;
  esac
done

REPO_SLUG="$(basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)")"
if [ -f "${REPO_SLUG}.php" ]; then
  SLUG="$REPO_SLUG"
else
  PLUGIN_FILE="$(find . -maxdepth 1 -name "*.php" -type f ! -name "uninstall.php" ! -name "render.php" | sort | head -1)"
  if [ -z "$PLUGIN_FILE" ]; then
    echo "::error::No main plugin PHP file found" >&2
    exit 1
  fi
  SLUG="$(basename "$PLUGIN_FILE" .php)"
fi

MAIN_FILE="$SLUG.php"
if [ ! -f "$MAIN_FILE" ]; then
  echo "::error::Main plugin file not found: $MAIN_FILE" >&2
  exit 1
fi

if ! head -n 1 "$MAIN_FILE" | grep -q '^<?php'; then
  echo "::error::$MAIN_FILE must start with <?php" >&2
  exit 1
fi

PLUGIN_NAME="$(grep -m1 '^[[:space:]]*\* Plugin Name:' "$MAIN_FILE" | sed 's/.*Plugin Name:[[:space:]]*//' | xargs)"
PLUGIN_VERSION="$(grep -m1 '^[[:space:]]*\* Version:' "$MAIN_FILE" | sed 's/.*Version:[[:space:]]*//' | xargs)"
TEXT_DOMAIN="$(grep -m1 '^[[:space:]]*\* Text Domain:' "$MAIN_FILE" | sed 's/.*Text Domain:[[:space:]]*//' | xargs)"

if [ -z "$PLUGIN_NAME" ] || [ -z "$PLUGIN_VERSION" ]; then
  echo "::error::$MAIN_FILE must include Plugin Name and Version headers" >&2
  exit 1
fi

if [ "$TEXT_DOMAIN" != "little-lightbox" ]; then
  echo "::error::Unexpected Text Domain: ${TEXT_DOMAIN:-missing}" >&2
  exit 1
fi

if [ ! -s "includes/um-updater.php" ]; then
  echo "::error::includes/um-updater.php is missing or empty" >&2
  exit 1
fi

if ! head -n 1 "includes/um-updater.php" | grep -q '^<?php'; then
  echo "::error::includes/um-updater.php is not a PHP file" >&2
  exit 1
fi

if [ -f "readme.txt" ]; then
  STABLE_TAG="$(grep -m1 '^Stable tag:' readme.txt | sed 's/Stable tag:[[:space:]]*//' | xargs)"
  if [ "$STABLE_TAG" != "$PLUGIN_VERSION" ]; then
    echo "::error::readme.txt Stable tag ($STABLE_TAG) does not match plugin Version ($PLUGIN_VERSION)" >&2
    exit 1
  fi
fi

if command -v php >/dev/null 2>&1; then
  while IFS= read -r -d '' file; do
    php -l "$file" >/dev/null
  done < <(find . \
    -path './.git' -prune -o \
    -path './release' -prune -o \
    -name '*.php' -type f -print0)
else
  echo "::warning::php not found; skipping PHP lint"
fi

if [ -n "$ZIP_PATH" ]; then
  if [ ! -f "$ZIP_PATH" ]; then
    echo "::error::ZIP not found: $ZIP_PATH" >&2
    exit 1
  fi

  if ! command -v unzip >/dev/null 2>&1; then
    echo "::error::unzip is required for ZIP validation" >&2
    exit 1
  fi

  ZIP_LIST="$(mktemp)"
  trap 'rm -f "$ZIP_LIST"' EXIT
  unzip -Z1 "$ZIP_PATH" > "$ZIP_LIST"

  grep -qx "$SLUG/$SLUG.php" "$ZIP_LIST" || {
    echo "::error::ZIP does not contain $SLUG/$SLUG.php" >&2
    exit 1
  }

  grep -qx "$SLUG/includes/um-updater.php" "$ZIP_LIST" || {
    echo "::error::ZIP does not contain $SLUG/includes/um-updater.php" >&2
    exit 1
  }

  FORBIDDEN='(^|/)(\.git|\.github|\.claude|\.openclaw|node_modules|vendor|tests|docs|scripts|release)(/|$)|(^|/)(README\.md|\.distignore|\.gitignore|composer\..*|package.*\.json|phpunit\..*|.*\.map|.*\.zip)$'
  if grep -Eq "$FORBIDDEN" "$ZIP_LIST"; then
    echo "::error::ZIP contains repository-only files:" >&2
    grep -E "$FORBIDDEN" "$ZIP_LIST" >&2
    exit 1
  fi
fi

echo "Validated $PLUGIN_NAME ($SLUG) v$PLUGIN_VERSION"
