#!/bin/bash
set -u
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
INSTALLER="$SCRIPT_DIR/ps2rk3326/install_ps2_system.sh"
ESUDO="${ESUDO-sudo}"

if [ ! -x "$INSTALLER" ]; then
    chmod +x "$INSTALLER" 2>/dev/null || true
fi

"$INSTALLER"
status=$?
if [ "$status" -eq 0 ]; then
    echo ""
    echo "A categoria PlayStation 2 foi instalada."
    if [ "${PLAY_SKIP_RESTART:-0}" = "1" ]; then
        echo "Reinício automático ignorado (PLAY_SKIP_RESTART=1)."
    else
        echo "Reiniciando o EmulationStation..."
        $ESUDO systemctl restart emulationstation
    fi
fi
exit "$status"
