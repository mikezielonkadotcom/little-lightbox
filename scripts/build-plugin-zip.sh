#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

RELEASE_DIR="${RELEASE_DIR:-release}"
REPO_SLUG="$(basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)")"
SLUG="${PLUGIN_SLUG:-}"

if [ -z "$SLUG" ]; then
  if [ -f "${REPO_SLUG}.php" ]; then
    SLUG="$REPO_SLUG"
  else
    PLUGIN_FILE="$(find . -maxdepth 1 -name "*.php" -type f ! -name "uninstall.php" ! -name "render.php" | sort | head -1)"
    if [ -n "$PLUGIN_FILE" ]; then
      SLUG="$(basename "$PLUGIN_FILE" .php)"
    else
      SLUG="$REPO_SLUG"
    fi
  fi
fi

VERSION="${PLUGIN_VERSION:-}"
if [ -z "$VERSION" ]; then
  if [ -n "${GITHUB_REF:-}" ] && [[ "$GITHUB_REF" =~ refs/tags/v(.+) ]]; then
    VERSION="${BASH_REMATCH[1]}"
  elif [ -f "$SLUG.php" ]; then
    VERSION="$(grep -m1 '^[[:space:]]*\* Version:' "$SLUG.php" | sed 's/.*Version:[[:space:]]*//' | xargs)"
  else
    VERSION="dev"
  fi
fi

DEST="$RELEASE_DIR/$SLUG"
rm -rf "$RELEASE_DIR"
mkdir -p "$DEST"

if [ -f ".distignore" ]; then
  rsync -a --exclude-from='.distignore' --exclude='release/' ./ "$DEST/"
else
  rsync -a \
    --exclude='.git' --exclude='.github' --exclude='.githooks' \
    --exclude='.claude' --exclude='.openclaw' --exclude='node_modules' \
    --exclude='vendor' --exclude='tests' --exclude='docs' --exclude='scripts' \
    --exclude='*.map' --exclude='*.zip' --exclude='release/' \
    --exclude='composer.*' --exclude='package*.json' --exclude='phpunit.*' \
    --exclude='.distignore' --exclude='.gitignore' --exclude='README.md' \
    ./ "$DEST/"
fi

find "$DEST" -name ".DS_Store" -delete 2>/dev/null || true
find "$DEST" -name "Thumbs.db" -delete 2>/dev/null || true

if [ ! -f "$DEST/$SLUG.php" ]; then
  echo "::error::Plugin file missing from release package: $DEST/$SLUG.php" >&2
  exit 1
fi

( cd "$RELEASE_DIR" && zip -qr "$SLUG.zip" "$SLUG" -x "*.DS_Store" "*.Thumbs.db" )

echo "Built $RELEASE_DIR/$SLUG.zip for $SLUG v$VERSION"

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  {
    echo "slug=$SLUG"
    echo "version=$VERSION"
    echo "zip=$RELEASE_DIR/$SLUG.zip"
  } >> "$GITHUB_OUTPUT"
fi
