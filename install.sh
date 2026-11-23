#!/bin/bash
# Installs or updates Motiondex: downloads the newest release from GitHub into /Applications and opens it.
# Use it from Terminal:
#   curl -fsSL https://raw.githubusercontent.com/mohaemedwally/motiondex-releases/main/install.sh | bash
set -e
REPO="mohaemedwally/motiondex-releases"
DEST="${MOTIONDEX_DEST:-/Applications}"   # (MOTIONDEX_DEST / MOTIONDEX_NO_OPEN are only for testing)
fail() { echo; echo "✗ $1"; exit 1; }

echo "▶︎ Finding the newest Motiondex…"
JSON="$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest")" || fail "Couldn't reach GitHub. Check the internet and try again."
URL="$(printf '%s' "$JSON" | grep -o '"browser_download_url": *"[^"]*\.zip"' | head -1 | sed 's/.*"\(https[^"]*\)"$/\1/')"
[ -n "$URL" ] || fail "Couldn't find the download. Try again in a minute."

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
echo "▶︎ Downloading $(basename "$URL")…"
curl -fL --progress-bar "$URL" -o "$TMP/motiondex.zip" || fail "The download stopped. Try again."
ditto -x -k "$TMP/motiondex.zip" "$TMP/x" || fail "The download is damaged. Try again."
APP="$(find "$TMP/x" -maxdepth 3 -type d -name 'Motiondex.app' ! -path '*__MACOSX*' | head -1)"
[ -n "$APP" ] || fail "Motiondex.app wasn't in the download."
VER="$(defaults read "$APP/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo "")"

if [ -z "$MOTIONDEX_NO_OPEN" ] && pgrep -x Motiondex >/dev/null; then
  echo "▶︎ Closing the Motiondex that's open…"
  osascript -e 'quit app "Motiondex"' >/dev/null 2>&1 || true
  sleep 1; pkill -x Motiondex 2>/dev/null || true
fi

echo "▶︎ Installing in $DEST…"
if [ -w "$DEST" ] && { [ ! -e "$DEST/Motiondex.app" ] || [ -w "$DEST/Motiondex.app" ]; }; then
  rm -rf "$DEST/Motiondex.app"
  ditto "$APP" "$DEST/Motiondex.app"
else
  echo "  Applications needs your Mac password (you won't see it as you type):"
  sudo rm -rf "$DEST/Motiondex.app"
  sudo ditto "$APP" "$DEST/Motiondex.app"
fi
xattr -dr com.apple.quarantine "$DEST/Motiondex.app" 2>/dev/null || true

echo
echo "✓ Motiondex ${VER} is installed."
if [ -z "$MOTIONDEX_NO_OPEN" ]; then open "$DEST/Motiondex.app"; fi
