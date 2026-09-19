#!/usr/bin/env bash
set -euo pipefail
PLUGIN_ID=dev.becerromarchy.workspace-taskbar
EXPECTED_PROTOCOL=4
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
: "${XDG_CACHE_HOME:=$HOME/.cache}"
: "${XDG_DATA_HOME:=$HOME/.local/share}"
CACHE="$XDG_CACHE_HOME/$PLUGIN_ID"
TARGET="$CACHE/cargo-target"
BUILD_SRC="$CACHE/backend-src"
DEST="$XDG_DATA_HOME/$PLUGIN_ID/bin"
command -v cargo >/dev/null || { echo "cargo is required. On Omarchy/Arch install the Rust toolchain first (for example: sudo pacman -S rust)." >&2; exit 2; }
command -v rustc >/dev/null || { echo "rustc is required." >&2; exit 2; }
command -v jq >/dev/null || { echo "jq is required for the build protocol check." >&2; exit 2; }
rm -rf -- "$BUILD_SRC"
mkdir -p "$BUILD_SRC" "$TARGET" "$DEST"
cp "$ROOT/backend/Cargo.toml" "$BUILD_SRC/Cargo.toml"
cp -R "$ROOT/backend/src" "$BUILD_SRC/src"
if [[ -f "$ROOT/backend/Cargo.lock" ]]; then
  cp "$ROOT/backend/Cargo.lock" "$BUILD_SRC/Cargo.lock"
else
  echo "NOTE: source Cargo.lock is not present in this development snapshot; generating it only in XDG cache." >&2
  (cd "$BUILD_SRC" && cargo generate-lockfile)
fi
CARGO_TARGET_DIR="$TARGET" cargo build --manifest-path "$BUILD_SRC/Cargo.toml" --locked --release
BIN="$TARGET/release/workspace-taskbar-backend"
probe=$($BIN version-json)
actual=$(jq -r '.protocolVersion // -1' <<<"$probe")
[[ "$actual" == "$EXPECTED_PROTOCOL" ]] || { echo "backend protocol $actual != expected $EXPECTED_PROTOCOL" >&2; exit 3; }
tmp="$DEST/.workspace-taskbar-backend.$$.tmp"
install -m 0755 "$BIN" "$tmp"
mv -f "$tmp" "$DEST/workspace-taskbar-backend"
"$DEST/workspace-taskbar-backend" version-json
