# Informações de compilação

## Alvo

O core foi compilado para Linux `aarch64`, CPU `Cortex-A35` e ISA `ARMv8-A`, destinado ao SoC Rockchip RK3326 dos portáteis R36S/R36H. A compilação usa `-mno-outline-atomics` para evitar helpers que assumam ARMv8.1/LSE incondicional.

## Código-fonte

O binário é baseado na revisão `04bde0df87ee7c0e2f0151b51bb2cc22c88541da` do código-fonte upstream de um emulador open-source de PlayStation 2, datada de 11 de agosto de 2026. A licença e a atribuição estão em [`LICENSES/UPSTREAM-EMULATOR-LICENSE.txt`](LICENSES/UPSTREAM-EMULATOR-LICENSE.txt) e em [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md).

## Adaptações do port

O Framework OpenGL foi ajustado para tratar `TARGET_PLATFORM_UNIX_AARCH64` como caminho GLES. O core libretro foi ligado contra o nome de biblioteca `libGLESv2.so.2`, mas solicita contexto OpenGL ES 3 em tempo de execução; a implementação concreta de EGL/GLES é fornecida pelo dArkOS instalado.

Foram adicionados shims locais para os símbolos C23 `__isoc23_*` gerados pelo toolchain Ubuntu 24.04. O binário ainda deve ser verificado contra a glibc da imagem dArkOS real. A compilação cruzada e o smoke test de carregamento via QEMU passaram, mas o ambiente de teste não possui KMS/DRM, GPU Mali-G31, áudio Rockchip ou controles físicos.

## Validação

Consulte [`BUILD_STATUS.md`](BUILD_STATUS.md) e [`darkos-compatibility-audit.md`](darkos-compatibility-audit.md). Não foram incluídos jogos, imagens de disco, BIOS proprietária ou o stub GLES utilizado exclusivamente fora do pacote para teste de carregamento.
