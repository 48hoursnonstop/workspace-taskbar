#!/usr/bin/env bash
set -euo pipefail

PLUGIN_ID=dev.becerromarchy.workspace-taskbar
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)

omarchy plugin update "$PLUGIN_ID" "$@"
omarchy plugin validate "$ROOT"
"$ROOT/scripts/build-backend.sh"
omarchy-shell shell rescanPlugins
"$ROOT/scripts/doctor.sh"
