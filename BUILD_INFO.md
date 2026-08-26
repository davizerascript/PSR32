# Informações de compilação

## Alvo

O core foi compilado para Linux `aarch64`, CPU `Cortex-A35` e ISA `ARMv8-A`, destinado ao SoC Rockchip RK3326 dos portáteis R36S/R36H. A compilação usa `-mno-outline-atomics` para evitar helpers que assumam ARMv8.1/LSE incondicional.

## Código-fonte

O binário é baseado na revisão `04bde0df87ee7c0e2f0151b51bb2cc22c88541da` do código-fonte upstream de um emulador open-source de PlayStation 2, datada de 11 de agosto de 2026. A licença e a atribuição estão em [`LICENSES/UPSTREAM-EMULATOR-LICENSE.txt`](LICENSES/UPSTREAM-EMULATOR-LICENSE.txt) e em [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md).

## Adaptações do port

O Framework OpenGL foi ajustado para tratar `TARGET_PLATFORM_UNIX_AARCH64` como caminho GLES. O core libretro foi ligado contra o nome de biblioteca `libGLESv2.so.2` e solicita explicitamente contexto **OpenGL ES 3.1** (`version_major=3`, `version_minor=1`) usando `RETRO_HW_CONTEXT_OPENGLES_VERSION`; o enum `RETRO_HW_CONTEXT_OPENGLES3` representa GLES 3.0 fixo. O caminho de VBlank não threaded também força `FlipImpl()` para evitar que `ProcessSingleFrame()` espere indefinidamente por `m_flipped` quando não há registros GS sujos. A implementação concreta de EGL/GLES é fornecida pelo dArkOS. O BuildID ELF desta revisão é `42665b8c65d64db050980c4321c06341cd537b4a`.

Foram adicionados shims locais para os símbolos C23 `__isoc23_*` gerados pelo toolchain Ubuntu 24.04. O binário ainda deve ser verificado contra a glibc da imagem dArkOS real. A compilação cruzada e o smoke test de carregamento via QEMU passaram após a alteração de negociação GLES 3.1 e da correção de VBlank. Um teste adicional com Mesa host criou EGL/GLES e executou `cubes_demo.elf`, `dungeon_game.elf` e `console_demo.elf` por 60 frames, com exit 0 e callbacks de vídeo; o ambiente de teste não possui KMS/DRM, GPU Mali-G31, áudio Rockchip ou controles físicos, portanto isso não substitui o R36S.

## Validação

O instalador do sistema PS2 registra `.elf` junto com ISO/CHD/CSO/CUE/BIN no `<extension>` do EmulationStation. Isso é necessário para que homebrews PS2 como `dungeon_game.elf` apareçam na categoria PS2; o core já declarava `elf` como extensão válida. Se uma entrada `ps2` antiga existir sem ELF, o instalador cria um backup datado e migra somente esse bloco; se ela já aceitar ELF, a execução é idempotente e não cria duplicata.

Consulte [`BUILD_STATUS.md`](BUILD_STATUS.md) e [`darkos-compatibility-audit.md`](darkos-compatibility-audit.md). Não foram incluídos jogos, imagens de disco, BIOS proprietária ou o stub GLES utilizado exclusivamente fora do pacote para teste de carregamento.
