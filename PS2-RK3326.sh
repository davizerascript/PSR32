#!/bin/bash
set -u

XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
PORTDIR="$SCRIPT_DIR/ps2rk3326"
CONFDIR="$PORTDIR/conf"
LOGFILE="$PORTDIR/log.txt"
mkdir -p "$CONFDIR"
# Start diagnostics before checking the ROM. This captures a bad or empty
# %ROM% expansion, which otherwise returned before the old log was created.
if : > "$LOGFILE" 2>/dev/null; then
    exec >>"$LOGFILE" 2>&1
    printf '%s\n' '--- PS2-RK3326 launcher invoked ---'
    printf 'launcher_pid=%s\n' "$$"
    printf 'launcher_script=%s\n' "$0"
    printf 'launcher_dir=%s\n' "$SCRIPT_DIR"
    printf 'argc=%s\n' "$#"
    printf 'rom_arg=%s\n' "${1-}"
    if command -v date >/dev/null 2>&1; then date '+launcher_invoked=%Y-%m-%dT%H:%M:%S%z' || true; fi
    if command -v pwd >/dev/null 2>&1; then printf 'cwd=%s\n' "$(pwd)"; fi
fi

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
    # PortMaster helper files are sourced with nounset disabled because some
    # dArkOS images leave optional fields (for example DEVICE_INFO_VERSION)
    # undefined. A missing optional field must not abort the PS2 launcher.
    set +u
    export controlfolder
    # shellcheck disable=SC1091
    source "$controlfolder/control.txt"
    [ -f "$controlfolder/device_info.txt" ] && source "$controlfolder/device_info.txt"
    [ -f "$controlfolder/mod_${CFW_NAME:-}.txt" ] && source "$controlfolder/mod_${CFW_NAME:-}.txt"
    # PortMaster helpers may also reference optional unset fields.
    get_controls 2>/dev/null || true
    ESUDO="${ESUDO-}"
    sdl_controllerconfig="${sdl_controllerconfig:-${SDL_GAMECONTROLLERCONFIG:-}}"
    set -u
else
    # The dArkOS wrappers run the emulator as the normal user. The outer
    # EmulationStation command already handles perfmax/perfnorm privileges;
    # sudo here would strip DEVICE_NAME, SDL and XDG variables.
    ESUDO="${ESUDO-}"
    sdl_controllerconfig="${SDL_GAMECONTROLLERCONFIG:-}"
fi
# Keep the emulator invocation unprivileged unless a PortMaster control file
# explicitly supplies an intentional wrapper (for example, a preserved-env
# sudo on a special device). This matches dArkOS's dreamcast.sh convention.
if [ -z "${ESUDO+x}" ]; then
    ESUDO=""
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
    echo "Coloque imagens ISO, CHD, CSO ou ELF homebrew em /roms/ps2." >&2
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

# The physical test reported each shoulder pair reversed: L1 appeared as
# L2 and R1 appeared as R2. Swap only semantic SDL labels, preserving the
# device-specific button indices. Set PS2_SWAP_SHOULDERS=0 to disable this
# compatibility fix on an image whose mapping is already correct.
ps2_swap_shoulder_tokens() {
    printf '%s' "$1" | sed \
        -e 's/leftshoulder:/__PS2_LEFT_SHOULDER__:/g' \
        -e 's/lefttrigger:/leftshoulder:/g' \
        -e 's/__PS2_LEFT_SHOULDER__:/lefttrigger:/g' \
        -e 's/rightshoulder:/__PS2_RIGHT_SHOULDER__:/g' \
        -e 's/righttrigger:/rightshoulder:/g' \
        -e 's/__PS2_RIGHT_SHOULDER__:/righttrigger:/g'
}
if [ "${PS2_SWAP_SHOULDERS:-1}" = "1" ] && [ -n "${sdl_controllerconfig:-}" ]; then
    sdl_controllerconfig="$(ps2_swap_shoulder_tokens "$sdl_controllerconfig")"
fi
export SDL_GAMECONTROLLERCONFIG="${sdl_controllerconfig:-${SDL_GAMECONTROLLERCONFIG:-}}"
# Match dArkOS perfmax: select its system EGL library, but do not force an
# SDL video backend. retrorun/RetroArch choose the backend for the firmware.
export SDL_VIDEO_EGL_DRIVER=libEGL.so
# Do not force an audio backend; dArkOS/retrorun selects its configured ALSA path.
# Do not override KMSDRM card, double-buffer, VSync or joystick backend here;
# those are firmware/frontend decisions and differ between R36 revisions.
export PLAY_RES_FACTOR="${PLAY_RES_FACTOR:-1}"

# Match the device profile used by dArkOS retrorun wrappers. Preserve a value
# supplied by PortMaster or a device-specific mod when one already exists.
if [ -z "${DEVICE_NAME:-}" ]; then
    if [ -e /boot/rk3326-r33s-linux.dtb ] || [ -e /boot/rk3326-r35s-linux.dtb ] || \
       [ -e /boot/rk3326-r36s-linux.dtb ] || [ -e /boot/rk3326-rg351mp-linux.dtb ] || \
       [ -e /boot/rk3326-g80ca-linux.dtb ]; then
        DEVICE_NAME="RG351MP"
    elif [ -e /boot/rk3326-odroidgo2-linux.dtb ] || [ -e /boot/rk3326-odroidgo3-linux.dtb ]; then
        DEVICE_NAME="RGB10"
    else
        DEVICE_NAME="RG351P"
    fi
fi
# PortMaster's device_info.txt may assign DEVICE_NAME without exporting it.
# retrorun-go2 needs the exported variable to select the RG351MP/R36 input
# profile and the correct physical display rotation.
export DEVICE_NAME

# Some PortMaster control files provide an ESUDO wrapper that preserves a
# whitelist of variables but omits DEVICE_NAME. retrorun-go2 needs this value
# after sudo to select the RG351MP/R36 input and display profile.
case "${ESUDO:-}" in
    sudo*|*/sudo*)
        case " ${ESUDO} " in
            *"--preserve-env=DEVICE_NAME"*) ;;
            *) ESUDO="${ESUDO} --preserve-env=DEVICE_NAME" ;;
        esac
        ;;
esac

# Let dArkOS apply its CPU governor, screen and suspend handling when available.
if declare -F pm_platform_helper >/dev/null 2>&1; then
    set +u
    pm_platform_helper "$PORTDIR/ps2rk3326_libretro.so" || true
    set -u
fi

# retrorun is the ArkOS wrapper used by the stock systems. It preserves the
# device's KMS/DRM setup, hotkeys, save paths and audio behavior. The fallback
# is useful on dArkOS variants where retrorun is not installed.
RETRORUN_BIN="${PLAY_RETRORUN-/usr/local/bin/retrorun}"
if command -v uname >/dev/null 2>&1; then uname -a || true; fi
printf 'rom_path=%s\n' "$ROM"
if command -v stat >/dev/null 2>&1; then stat -c 'rom_size_bytes=%s' "$ROM" 2>/dev/null || true; fi
printf 'core_path=%s\n' "$PORTDIR/ps2rk3326_libretro.so"
printf 'retrorun_path=%s\n' "$RETRORUN_BIN"
printf 'esudo=%s\n' "${ESUDO:-}"
printf 'xdg_config_home=%s\n' "$XDG_CONFIG_HOME"
printf 'sdl_videodriver=%s\n' "${SDL_VIDEODRIVER:-}"
printf 'sdl_video_egl_driver=%s\n' "${SDL_VIDEO_EGL_DRIVER:-}"
printf 'device_name=%s\n' "${DEVICE_NAME:-}"
printf 'display_orientation=%s\n' "${DISPLAY_ORIENTATION:-}"
printf 'sdl_kmsdrm_orientation=%s\n' "${SDL_KMSDRM_ORIENTATION:-}"
printf 'sdl_kmsdrm_rotation=%s\n' "${SDL_KMSDRM_ROTATION:-}"
printf 'sdl_gamecontrollerconfig_bytes=%s\n' "${#SDL_GAMECONTROLLERCONFIG}"
printf 'ps2_swap_shoulders=%s\n' "${PS2_SWAP_SHOULDERS:-1}"
if command -v file >/dev/null 2>&1; then
    file "$PORTDIR/ps2rk3326_libretro.so" 2>/dev/null || true
    [ -e "$RETRORUN_BIN" ] && file "$RETRORUN_BIN" 2>/dev/null || true
fi
if command -v readelf >/dev/null 2>&1; then
    readelf -d "$PORTDIR/ps2rk3326_libretro.so" 2>/dev/null | grep 'NEEDED' || true
fi
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
    set +u
    pm_finish || true
    set -u
fi
if [ -w /dev/tty1 ]; then
    printf '\033c' >/dev/tty1 || true
fi
exit "$status"
