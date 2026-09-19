#!/usr/bin/env bash
set -euo pipefail
PLUGIN_ID=workspace-taskbar
EXPECTED_PROTOCOL=5
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/$PLUGIN_ID"
DEST="${XDG_DATA_HOME:-$HOME/.local/share}/$PLUGIN_ID/bin"
for tool in cargo rustc jq; do
  command -v "$tool" >/dev/null || { echo "$tool is required; install the Rust toolchain and jq before building." >&2; exit 2; }
done
[[ -f "$ROOT/backend/Cargo.lock" ]] || { echo 'Release is missing backend/Cargo.lock. Refusing an unpinned build.' >&2; exit 2; }
mkdir -p "$CACHE" "$DEST"
BUILD_SRC=$(mktemp -d "$CACHE/build.XXXXXX")
tmp=""
trap 'rm -rf -- "$BUILD_SRC"; if [[ -n $tmp ]]; then rm -f -- "$tmp"; fi' EXIT
cp "$ROOT/backend/Cargo.toml" "$ROOT/backend/Cargo.lock" "$BUILD_SRC/"
cp -R "$ROOT/backend/src" "$BUILD_SRC/src"
TARGET="$CACHE/cargo-target"
CARGO_TARGET_DIR="$TARGET" cargo build --manifest-path "$BUILD_SRC/Cargo.toml" --locked --release
BIN="$TARGET/release/workspace-taskbar-backend"
probe=$("$BIN" version-json)
jq -e --argjson expected "$EXPECTED_PROTOCOL" '.ok == true and .protocolVersion == $expected and .stateSchemaVersion == 1' <<<"$probe" >/dev/null
# Copy first, validate that exact copy, then replace the installed inode.
tmp=$(mktemp "$DEST/.workspace-taskbar-backend.XXXXXX")
install -m 0755 "$BIN" "$tmp"
"$tmp" --protocol "$EXPECTED_PROTOCOL" version-json >/dev/null
mv -f -- "$tmp" "$DEST/workspace-taskbar-backend"
tmp=""
"$DEST/workspace-taskbar-backend" version-json
