#!/bin/bash
set -u

# Instala uma entrada PS2 no ArkOS/dArkOS. O passo é separado do launcher
# PortMaster para permitir backup e remoção controlados pelo usuário.
ESCFG="${ESCFG_OVERRIDE:-/etc/emulationstation/es_systems.cfg}"
ROMDIR="${PLAY_ROMDIR:-/roms/ps2}"
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
LAUNCHER="$SCRIPT_DIR/../PS2-RK3326.sh"
ESUDO="${ESUDO-sudo}"

if [ ! -f "$ESCFG" ]; then
    echo "Arquivo do EmulationStation não encontrado: $ESCFG" >&2
    exit 1
fi
if [ ! -x "$LAUNCHER" ]; then
    chmod +x "$LAUNCHER" 2>/dev/null || true
fi

if grep -q '<name>ps2</name>' "$ESCFG"; then
    echo "O sistema ps2 já está instalado em $ESCFG"
    exit 0
fi

BACKUP="$ESCFG.ps2rk3326.bak.$(date +%Y%m%d-%H%M%S)"
TMP="$(mktemp)"
cleanup() { rm -f "$TMP"; }
trap cleanup EXIT

# O comando usa aspas porque caminhos podem conter espaços. O EmulationStation
# substitui %ROM% pelo caminho da imagem ISO/CHD/CSO/ELF selecionada.
cat > "$TMP" <<EOF
  <system>
    <name>ps2</name>
    <fullname>PlayStation 2</fullname>
    <path>$ROMDIR</path>
    <extension>.iso .ISO .chd .CHD .cso .CSO .cue .CUE .bin .BIN .elf .ELF</extension>
    <command>$LAUNCHER &quot;%ROM%&quot;</command>
    <platform>ps2</platform>
    <theme>ps2</theme>
  </system>
EOF

$ESUDO cp -a "$ESCFG" "$BACKUP"
$ESUDO awk -v blockfile="$TMP" 'BEGIN{done=0; while((getline line < blockfile)>0) block=block line ORS; close(blockfile)} /<\/systemList>/{if(!done){printf "%s", block; done=1}} {print} END{if(!done) exit 2}' "$ESCFG" > "$TMP.out"
if [ "$?" -ne 0 ]; then
    echo "Não foi possível localizar </systemList>; nenhum arquivo foi alterado." >&2
    exit 1
fi
$ESUDO cp "$TMP.out" "$ESCFG"
$ESUDO mkdir -p "$ROMDIR"

echo "Sistema PS2 instalado. Backup: $BACKUP"
echo "Coloque suas imagens legais em $ROMDIR e reinicie o EmulationStation."
exit 0
