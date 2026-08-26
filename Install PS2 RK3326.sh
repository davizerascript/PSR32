#!/bin/bash
set -u
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
INSTALLER="$SCRIPT_DIR/ps2rk3326/install_ps2_system.sh"

if [ ! -x "$INSTALLER" ]; then
    chmod +x "$INSTALLER" 2>/dev/null || true
fi

"$INSTALLER"
status=$?
if [ "$status" -eq 0 ]; then
    echo ""
    echo "A categoria PlayStation 2 foi instalada."
    echo "Reiniciando o EmulationStation..."
    sudo systemctl restart emulationstation
fi
exit "$status"
