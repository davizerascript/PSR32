# Status do port PS2-RK3326

**Data:** 26 de agosto de 2026  
**Status:** experimental; compilado, auditado estaticamente e com smoke test de carregamento AArch64 repetido após a revisão GLES 3.1; ainda sem validação em um R36S/R36H físico.

## O que foi concluído

Foi criado um port ARM64 de PlayStation 2 para Linux/RK3326, com launcher PortMaster, caminho prioritário pelo `retrorun` 64-bit do dArkOS e fallback direto para RetroArch. O port aceita imagens legais ISO, CHD, CSO e CUE/BIN e não inclui jogos, BIOS externa ou firmware proprietário.

A categoria dedicada **PlayStation 2** é opcional. O instalador cria um backup datado de `es_systems.cfg`, insere uma entrada idempotente e cria `/roms/ps2`; nenhum DTB ou `boot.ini` é substituído.

## Testes realizados

| Teste | Resultado |
|---|---:|
| Compilação cruzada AArch64/Cortex-A35/ARMv8-A | OK |
| Carregamento do core via QEMU AArch64 após a revisão GLES 3.1 | OK — `name=Play!`, `04bde0d`, `need_fullpath=1` |
| Exports `retro_init`, `retro_run`, `retro_load_game` | OK |
| Manifesto JSON, metadados XML e shell scripts | OK |
| Launcher com retrorun e fallback RetroArch simulados | OK |
| Launcher clicado sem argumento inicia o instalador local | OK |
| Launcher registra código de erro do emulador em `log.txt` | OK |
| Extração do ZIP no nível `/roms/ports/` e clique de instalação | OK |
| Instalação XML com backup e idempotência | OK |
| ZIP sem stub GLES ou arquivos de jogo | OK |
| Core host com EGL/GLES Mesa e `retro_load_game` de ELF homebrew MIT | Carregamento OK; `retro_run` completo não é considerado válido neste harness |
| GPU Mali-G31, KMS/DRM, áudio e controles físicos | Pendente |
| FPS e compatibilidade de jogos 3D | Pendente |

## Auditoria do dArkOS

O checkout [dArkOSRE-R36](https://github.com/southoz/dArkOSRE-R36) foi atualizado e inspecionado. O snapshot de rootfs auditado informa `03082026`. Os arquivos confirmam Ports em `/roms/ports/*.sh`, wrappers oficiais com `/usr/local/bin/retrorun` e `/home/ark/.config/retrorun.cfg`, RetroArch 64-bit com driver `gl` e input `udev`, áudio `alsathread`, viewport 640×480 e seleção EGL via `SDL_VIDEO_EGL_DRIVER=libEGL.so`.

O próprio checkout não contém o binário final `retrorun`, o arquivo `retrorun.cfg` nem as bibliotecas EGL/GLES. Esses componentes são fornecidos pela imagem instalada no cartão e precisam ser verificados no aparelho. Consulte [`darkos-compatibility-audit.md`](darkos-compatibility-audit.md) para os detalhes e comandos de diagnóstico.

Após um relato de clique sem abertura, o launcher foi corrigido para suportar dois caminhos: quando recebe uma imagem via `%ROM%`, encaminha-a ao retrorun; quando é clicado diretamente sem argumento, chama o instalador local. Também passou a retornar e registrar o código de saída do emulador. Nesta revisão, o log foi reforçado antes da chamada ao emulador com arquitetura, ROM, tamanho, core, dependências ELF detectáveis e variáveis SDL relevantes. O teste offline em um cartão simulado passou com o layout real: os scripts ficaram diretamente em `/roms/ports/`, o core permaneceu em `ps2rk3326/` e a categoria PS2 foi inserida com backup.

## Limitações importantes

A compilação passou no host e o carregamento do core passou no QEMU. Um frontend host criou EGL/GLES 3.2 Mesa e conseguiu `retro_load_game`, mas não completou um `retro_run` do ELF homebrew no sandbox; esse resultado não é usado como prova de funcionamento do jogo e não substitui o R36. O contexto OpenGL ES real do Mali-G31, a versão da glibc, o comportamento do retrorun, o áudio, o mapeamento físico e o desempenho de jogos 3D ainda precisam ser medidos. Não há promessa de 30 ou 60 FPS. O relato de NFSU2 continua pendente de `ps2rk3326/log.txt` da nova revisão.

O código-fonte upstream e todos os avisos de terceiros estão documentados em [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md) e em [`LICENSES/`](LICENSES/).
