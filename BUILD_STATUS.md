# Status do port PS2-RK3326

**Data:** 26 de agosto de 2026  
**Status:** experimental; compilado, auditado estaticamente, com smoke test AArch64 e com execução host de homebrews por 60 frames após as correções de GLES, extensão ELF e VBlank; ainda sem validação em um R36S/R36H físico.

## O que foi concluído

Foi criado um port ARM64 de PlayStation 2 para Linux/RK3326, com launcher PortMaster, caminho prioritário pelo `retrorun` 64-bit do dArkOS e fallback direto para RetroArch. O port aceita imagens legais ISO, CHD, CSO, CUE/BIN e ELF homebrew; não inclui jogos comerciais, BIOS externa ou firmware proprietário.

A categoria dedicada **PlayStation 2** é opcional. O instalador cria um backup datado de `es_systems.cfg`, insere uma entrada nova ou migra somente uma entrada `ps2` antiga sem `.elf`, preserva os demais sistemas e cria `/roms/ps2`; nenhum DTB ou `boot.ini` é substituído. Se a entrada já aceita ELF, a execução é idempotente e não cria duplicata.

## Testes realizados

| Teste | Resultado |
|---|---:|
| Compilação cruzada AArch64/Cortex-A35/ARMv8-A | OK |
| Carregamento do core via QEMU AArch64 após as correções | OK — `name=Play!`, `04bde0d`, `need_fullpath=1`; BuildID `42665b8c65d64db050980c4321c06341cd537b4a` |
| Exports `retro_init`, `retro_run`, `retro_load_game` | OK |
| Manifesto JSON, metadados XML e shell scripts | OK |
| Launcher com retrorun e fallback RetroArch simulados | OK |
| Launcher tolerante a `DEVICE_INFO_VERSION` ausente no helper PortMaster | OK — erro reproduzido com `set -u`, corrigido e retestado até o retrorun |
| Launcher clicado sem argumento inicia o instalador local | OK |
| Launcher registra código de erro do emulador em `log.txt` | OK |
| Extração do ZIP no nível `/roms/ports/` e clique de instalação | OK |
| Instalação XML inicial, migração de entrada antiga, backup e idempotência | OK |
| ZIP sem stub GLES ou arquivos de jogo | OK |
| Core host com EGL/GLES Mesa e ELF homebrew MIT | OK — `cubes_demo`, `dungeon_game`, `console_demo` e `play_adpcm_demo` completaram 60 frames com exit 0 após a correção de VBlank; o ADPCM produziu 29.700 frames de áudio no callback host |
| GPU Mali-G31, KMS/DRM, áudio e controles físicos no R36S | Pendente |
| FPS e compatibilidade de jogos comerciais/3D no R36S | Pendente |

## Auditoria do dArkOS

O checkout [dArkOSRE-R36](https://github.com/southoz/dArkOSRE-R36) foi atualizado e inspecionado. O snapshot de rootfs auditado informa `03082026`. Os arquivos confirmam Ports em `/roms/ports/*.sh`, wrappers oficiais com `/usr/local/bin/retrorun` e `/home/ark/.config/retrorun.cfg`, RetroArch 64-bit com driver `gl` e input `udev`, áudio `alsathread`, viewport 640×480 e seleção EGL via `SDL_VIDEO_EGL_DRIVER=libEGL.so`.

O próprio checkout não contém o binário final `retrorun`, o arquivo `retrorun.cfg` nem as bibliotecas EGL/GLES. Esses componentes são fornecidos pela imagem instalada no cartão e precisam ser verificados no aparelho. Consulte [`darkos-compatibility-audit.md`](darkos-compatibility-audit.md) para os detalhes e comandos de diagnóstico.

Após um relato de clique sem abertura, o launcher foi corrigido para suportar dois caminhos: quando recebe uma imagem via `%ROM%`, encaminha-a ao retrorun; quando é clicado diretamente sem argumento, chama o instalador local. Também passou a retornar e registrar o código de saída do emulador. Nesta revisão, o diagnóstico começa antes da validação da ROM, registrando argumento, diretório, arquitetura, ROM, tamanho, core, dependências ELF detectáveis e variáveis SDL disponíveis; o instalador também grava `install.log`. O log físico recebido mostrou que o helper `device_info.txt` do dArkOS referenciava `DEVICE_INFO_VERSION` sem defini-la; como o launcher usava `set -u`, ele terminava antes do retrorun. A leitura dos helpers agora ocorre com `nounset` temporariamente desativado, e o caso foi reproduzido em fixture controlada com resultado `NOUNSET_HELPER=PASS`. A comparação com o dArkOS mostrou que o comando de sistema deve usar `sudo perfmax %GOVERNOR% %ROM%; nice -n -19 ...; sudo perfnorm`; a entrada PS2 foi alinhada a essa moldura, e o launcher não força backend SDL/KMSDRM. O instalador registra `.elf` junto com ISO/CHD/CSO/CUE/BIN no `es_systems.cfg`, permitindo que homebrews como `dungeon_game.elf` apareçam na categoria PS2. Se o usuário já tiver uma entrada PS2 antiga, a nova revisão cria backup datado e substitui somente o bloco PS2 sem duplicar a categoria. O teste offline em um cartão simulado passou com o layout real: os scripts ficaram diretamente em `/roms/ports/`, o core permaneceu em `ps2rk3326/` e a categoria PS2 foi inserida ou migrada com backup.

## Limitações importantes

A compilação passou no host e o carregamento do core passou no QEMU. Depois de reproduzir o ciclo de frames, foi identificado e corrigido um deadlock: no caminho GS não threaded do libretro, `Flip()` podia não chamar `FlipImpl()` quando `m_regsDirty` era falso, deixando `ProcessSingleFrame()` esperando `m_flipped`. Com `FLIP_FLAG_FORCE` no VBlank não threaded, três demos completaram 60 frames no host x86/Mesa. Esse resultado não substitui o R36. A comparação com o cabeçalho oficial libretro também corrigiu o enum: `RETRO_HW_CONTEXT_OPENGLES_VERSION` é usado para negociar explicitamente GLES 3.1; `RETRO_HW_CONTEXT_OPENGLES3` é o enum fixo de GLES 3.0. O contexto OpenGL ES real do Mali-G31, a versão da glibc, o comportamento do retrorun, o áudio, o mapeamento físico e o desempenho de jogos 3D ainda precisam ser medidos. Não há promessa de 30 ou 60 FPS. O relato de NFSU2 continua pendente de `ps2rk3326/log.txt` da nova revisão.

O código-fonte upstream e todos os avisos de terceiros estão documentados em [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md) e em [`LICENSES/`](LICENSES/).
