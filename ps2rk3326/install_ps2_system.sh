#!/bin/bash
set -u

# Instala ou migra uma entrada PS2 no ArkOS/dArkOS. O passo é separado do
# launcher PortMaster para permitir instalação offline e backup controlado.
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

TMP="$(mktemp)"
TMP_OUT="$(mktemp)"
cleanup() { rm -f "$TMP" "$TMP_OUT"; }
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

# 0 = não existe, 1 = existe sem ELF, 2 = já contém ELF.
PS2_STATUS="$(awk '
BEGIN { in_system=0; is_ps2=0; has_elf=0 }
/<system[[:space:]>]/ && !in_system {
    in_system=1; is_ps2=0; has_elf=0
}
in_system {
    if ($0 ~ /<name>[[:space:]]*ps2[[:space:]]*<\/name>/) is_ps2=1
    if ($0 ~ /<extension>[^<]*\.elf([[:space:]]|<)/) has_elf=1
}
in_system && /<\/system>/ {
    if (is_ps2) { print (has_elf ? 2 : 1); exit }
    in_system=0
}
END { if (!is_ps2) print 0 }
' "$ESCFG" | tail -n 1)"

if [ "$PS2_STATUS" = "2" ]; then
    mkdir -p "$ROMDIR" 2>/dev/null || true
    echo "O sistema ps2 já está instalado e já aceita ELF em $ESCFG"
    exit 0
fi

BACKUP="$ESCFG.ps2rk3326.bak.$(date +%Y%m%d-%H%M%S)"
if ! $ESUDO cp -a "$ESCFG" "$BACKUP"; then
    echo "Não foi possível criar o backup $BACKUP; nenhum arquivo foi alterado." >&2
    exit 1
fi

if [ "$PS2_STATUS" = "1" ]; then
    # Migração: preserva todos os demais sistemas e configurações, trocando
    # apenas o bloco <system> cujo <name> é ps2.
    if ! awk -v blockfile="$TMP" '
    BEGIN {
        while ((getline line < blockfile) > 0) block=block line ORS
        close(blockfile)
        in_system=0; is_ps2=0; replaced=0; current=""
    }
    !in_system && /<system[[:space:]>]/ {
        in_system=1; is_ps2=0; current=$0 ORS
        if ($0 ~ /<name>[[:space:]]*ps2[[:space:]]*<\/name>/) is_ps2=1
        next
    }
    !in_system { print; next }
    in_system {
        current=current $0 ORS
        if ($0 ~ /<name>[[:space:]]*ps2[[:space:]]*<\/name>/) is_ps2=1
        if ($0 ~ /<\/system>/) {
            if (is_ps2) { printf "%s", block; replaced=1 }
            else printf "%s", current
            in_system=0; is_ps2=0; current=""
        }
        next
    }
    END {
        if (in_system) printf "%s", current
        if (!replaced) exit 2
    }
    ' "$ESCFG" > "$TMP_OUT"; then
        echo "Não foi possível localizar o bloco PS2; o backup foi preservado e nenhum arquivo foi alterado." >&2
        exit 1
    fi
    ACTION="migrado"
else
    # Instalação inicial: insere o novo bloco antes de </systemList>.
    if ! awk -v blockfile="$TMP" '
    BEGIN { done=0; while ((getline line < blockfile) > 0) block=block line ORS; close(blockfile) }
    /<\/systemList>/ {
        if (!done) { printf "%s", block; done=1 }
    }
    { print }
    END { if (!done) exit 2 }
    ' "$ESCFG" > "$TMP_OUT"; then
        echo "Não foi possível localizar </systemList>; o backup foi preservado e nenhum arquivo foi alterado." >&2
        exit 1
    fi
    ACTION="instalado"
fi

if ! $ESUDO cp "$TMP_OUT" "$ESCFG"; then
    echo "Não foi possível gravar $ESCFG; o backup $BACKUP foi preservado." >&2
    exit 1
fi
if ! $ESUDO mkdir -p "$ROMDIR"; then
    echo "A entrada PS2 foi $ACTION, mas não foi possível criar $ROMDIR." >&2
    exit 1
fi

echo "Sistema PS2 $ACTION. Backup: $BACKUP"
echo "Coloque suas imagens legais em $ROMDIR e reinicie o EmulationStation."
exit 0
