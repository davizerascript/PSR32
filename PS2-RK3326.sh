#!/bin/bash
set -u

XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
PORTDIR="$SCRIPT_DIR/ps2rk3326"
CONFDIR="$PORTDIR/conf"
mkdir -p "$CONFDIR"

# Locate PortMaster's shared control helpers.
if [ -d "/opt/system/Tools/PortMaster" ]; then
    controlfolder="/opt/system/Tools/PortMaster"
elif [ -d "/opt/tools/PortMaster" ]; then
    controlfolder="/opt/tools/PortMaster"
elif [ -d "$XDG_DATA_HOME/PortMaster" ]; then
    controlfolder="$XDG_DATA_HOME/PortMaster"
else
    controlfolder="/roms/ports/PortMaster"
fi

if [ -f "$controlfolder/control.txt" ]; then
    # shellcheck disable=SC1091
    source "$controlfolder/control.txt"
    [ -f "$controlfolder/device_info.txt" ] && source "$controlfolder/device_info.txt"
    [ -f "$controlfolder/mod_${CFW_NAME:-}.txt" ] && source "$controlfolder/mod_${CFW_NAME:-}.txt"
    get_controls 2>/dev/null || true
else
    ESUDO="${ESUDO-sudo}"
    sdl_controllerconfig="${SDL_GAMECONTROLLERCONFIG:-}"
fi
# Some control.txt files do not export ESUDO. Use no privilege wrapper when
# dArkOS already launched this script as root, while preserving an intentional
# empty ESUDO for offline tests and PortMaster environments.
if [ -z "${ESUDO+x}" ]; then
    if [ "$(id -u)" -eq 0 ]; then
        ESUDO=""
    else
        ESUDO="sudo"
    fi
fi

ROM="${1:-}"
if [ -z "$ROM" ]; then
    # A direct click on the visible launcher is common on dArkOS. Make that
    # click useful instead of exiting with no visible action: run the local
    # installer, which creates the PS2 system entry. Game launches pass ROM.
    INSTALLER="$SCRIPT_DIR/Install PS2 RK3326.sh"
    if [ -x "$INSTALLER" ]; then
        exec "$INSTALLER"
    fi
    echo "Port PS2-RK3326: selecione um jogo na categoria PlayStation 2." >&2
    echo "Coloque imagens ISO, CHD ou CSO em /roms/ps2." >&2
    exit 1
fi
if [ ! -f "$ROM" ]; then
    echo "Imagem não encontrada: $ROM" >&2
    exit 1
fi
if [ ! -f "$PORTDIR/ps2rk3326_libretro.so" ]; then
    echo "Core PS2-RK3326 não encontrado em $PORTDIR/ps2rk3326_libretro.so" >&2
    exit 1
fi

# Keep all emulator-generated data inside the port directory.
export XDG_CONFIG_HOME="$CONFDIR/config"
export XDG_DATA_HOME="$CONFDIR/data"
export XDG_CACHE_HOME="$CONFDIR/cache"
mkdir -p "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_CACHE_HOME"

export SDL_GAMECONTROLLERCONFIG="${sdl_controllerconfig:-${SDL_GAMECONTROLLERCONFIG:-}}"
export SDL_AUDIODRIVER="${SDL_AUDIODRIVER:-alsa}"
export SDL_VIDEODRIVER="${SDL_VIDEODRIVER:-kmsdrm}"
export SDL_VIDEO_KMSDRM_DOUBLE_BUFFER=1
export SDL_VIDEO_KMSDRM_CARD_INDEX=0
# dArkOS perfmax/perfnorm select the system EGL implementation this way.
export SDL_VIDEO_EGL_DRIVER="${SDL_VIDEO_EGL_DRIVER:-libEGL.so}"
export SDL_JOYSTICK_HIDAPI=0
export SDL_JOYSTICK_DEADZONE=12000
export vblank_mode=0
export SDL_RENDER_VSYNC=0
export PLAY_RES_FACTOR="${PLAY_RES_FACTOR:-1}"

# Match the device profile used by dArkOS retrorun wrappers. Preserve a value
# supplied by PortMaster or a device-specific mod when one already exists.
if [ -z "${DEVICE_NAME:-}" ]; then
    if [ -e /boot/rk3326-r33s-linux.dtb ] || [ -e /boot/rk3326-r35s-linux.dtb ] || \
       [ -e /boot/rk3326-r36s-linux.dtb ] || [ -e /boot/rk3326-rg351mp-linux.dtb ] || \
       [ -e /boot/rk3326-g80ca-linux.dtb ]; then
        export DEVICE_NAME="RG351MP"
    elif [ -e /boot/rk3326-odroidgo2-linux.dtb ] || [ -e /boot/rk3326-odroidgo3-linux.dtb ]; then
        export DEVICE_NAME="RGB10"
    else
        export DEVICE_NAME="RG351P"
    fi
fi

# Let dArkOS apply its CPU governor, screen and suspend handling when available.
if declare -F pm_platform_helper >/dev/null 2>&1; then
    pm_platform_helper "$PORTDIR/ps2rk3326_libretro.so" || true
fi

LOGFILE="$PORTDIR/log.txt"
: > "$LOGFILE"
exec > >(tee "$LOGFILE") 2>&1

# retrorun is the ArkOS wrapper used by the stock systems. It preserves the
# device's KMS/DRM setup, hotkeys, save paths and audio behavior. The fallback
# is useful on dArkOS variants where retrorun is not installed.
RETRORUN_BIN="${PLAY_RETRORUN-/usr/local/bin/retrorun}"
status=0
if [ -x "$RETRORUN_BIN" ]; then
    ROMDIR="$(dirname "$ROM")"
    BIOSDIR="${ROMDIR%/*}/bios"
    mkdir -p "$BIOSDIR" 2>/dev/null || true
    $ESUDO "$RETRORUN_BIN" \
        -c /home/ark/.config/retrorun.cfg \
        --triggers \
        -s "$ROMDIR" \
        -d "$BIOSDIR" \
        "$PORTDIR/ps2rk3326_libretro.so" "$ROM"
    status=$?
else
    RETROARCH="${PLAY_RETROARCH-/usr/local/bin/retroarch}"
    [ -x "$RETROARCH" ] || RETROARCH="$(command -v retroarch || true)"
    if [ -z "$RETROARCH" ]; then
        echo "RetroArch/retrorun não foi encontrado no dArkOS." >&2
        exit 1
    fi
    $ESUDO "$RETROARCH" -L "$PORTDIR/ps2rk3326_libretro.so" "$ROM"
    status=$?
fi
printf 'emulator_exit_status=%s\n' "$status"
if [ "$status" -ne 0 ]; then
    echo "O emulador terminou com erro. Consulte $LOGFILE." >&2
fi

if declare -F pm_finish >/dev/null 2>&1; then
    pm_finish
fi
if [ -w /dev/tty1 ]; then
    printf '\033c' >/dev/tty1 || true
fi
exit "$status"
