#!/usr/bin/env bash
set -euo pipefail

PLUGIN_ID=dev.becerromarchy.workspace-taskbar
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
EXPECTED="$HOME/.config/omarchy/plugins/$PLUGIN_ID"

command -v omarchy >/dev/null || { echo "Omarchy CLI not found." >&2; exit 2; }

root_real=$(realpath -m "$ROOT")
expected_real=$(realpath -m "$EXPECTED")
if [[ $root_real != "$expected_real" ]]; then
  cat >&2 <<MSG
This checkout must live at:
  $EXPECTED
Current checkout:
  $ROOT

Move/clone the repository to Omarchy's documented third-party plugin path first.
MSG
  exit 2
fi

omarchy plugin validate "$ROOT"
"$ROOT/scripts/build-backend.sh"
omarchy-shell shell rescanPlugins
omarchy plugin enable "$PLUGIN_ID" --section left --index 1
"$ROOT/scripts/doctor.sh"
cat <<MSG
Optional official Hyprbars titlebar integration:
  $ROOT/scripts/setup-hyprbars.sh
MSG
