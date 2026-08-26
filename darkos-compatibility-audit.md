# Auditoria direta do dArkOS para o port ARM64

**Data da auditoria:** 26 de agosto de 2026  
**Projeto auditado:** [dArkOSRE-R36](https://github.com/southoz/dArkOSRE-R36)  
**Snapshot local do rootfs:** `.VERSION = 03082026`  
**HEAD da branch `main`:** `3f372c85aa53a26b265c3dc0c2661ec0fae5faf0`

## O que foi confirmado nos arquivos

| Componente | Evidência encontrada | Consequência para o port |
|---|---|---|
| Menu Ports | `es_systems.cfg` usa `/roms/ports/`, extensão `.sh` e executa `%ROM%` | O launcher PortMaster pode aparecer e ser chamado diretamente pelo menu. |
| Preparação de desempenho | O comando de Ports executa `perfmax` antes e `perfnorm` depois | O port recebe o mesmo ciclo de governor usado pelos outros sistemas. |
| Driver gráfico do RetroArch | `retroarch.cfg` define `video_driver = "gl"`, tela cheia, viewport 640×480, `video_threaded = "true"` e VSync ativo | A rota correta é RetroArch/retrorun com o driver GL do firmware, não VulkanDirect. |
| Controle | `retroarch.cfg` define `input_driver = "udev"`; há autoconfiguração udev para o GO-Super Gamepad | O port deve preservar `SDL_GAMECONTROLLERCONFIG` e deixar o mapeamento base ao dArkOS/PortMaster. |
| Áudio | `audio_driver = "alsathread"`, `audio_out_rate = "48000"` e latência 128 | O launcher não deve distribuir uma biblioteca de áudio própria. |
| Wrapper 64-bit | `dreamcast.sh`, `atomiswave.sh` e `naomi.sh` chamam `/usr/local/bin/retrorun` com `-c /home/ark/.config/retrorun.cfg --triggers -s ... -d ... <core> <rom>` | O launcher Play! segue a mesma convenção para o core AArch64. |
| Perfil de dispositivo | Os wrappers classificam vários DTBs RK3326/R36 como perfil `RG351MP` e exportam `DEVICE_NAME` | O launcher agora define esse perfil apenas quando o ambiente não forneceu outro. |
| EGL | `perfmax` e `perfnorm` exportam `SDL_VIDEO_EGL_DRIVER=libEGL.so` | O launcher agora replica essa variável. |
| Variantes | `r36_config.sh` usa `/boot/dtb/r36_devices.ini`, esquemas de controle e fallback 640×480 | Não é seguro substituir DTB, `boot.ini` ou configuração global automaticamente. |

## O que não foi encontrado no checkout

O repositório não contém o binário `/usr/local/bin/retrorun`, o arquivo `/home/ark/.config/retrorun.cfg` nem as bibliotecas de execução `libEGL.so`/`libGLES*.so`. Isso significa que esses componentes pertencem à imagem instalada do dArkOS e não podem ser validados apenas a partir dos arquivos-fonte do firmware. A auditoria confirma a **interface esperada**, não a presença ou a versão exata no cartão do usuário.

O arquivo do RetroArch confirma `video_driver = "gl"` e `input_driver = "udev"`, mas não informa sozinho se o contexto GLES 3 solicitado pelo core será criado com sucesso. O core requer um contexto OpenGL ES 3; essa parte precisa de teste no aparelho com o driver real do R36.

## Ajustes feitos no port após a auditoria

O launcher foi alinhado ao dArkOS para exportar `SDL_VIDEO_EGL_DRIVER=libEGL.so`, respeitar `ESUDO=""` quando o PortMaster não requer sudo, aceitar `DEVICE_NAME` já fornecido e reconhecer DTBs RK3326/R36 para o perfil `RG351MP`. O instalador da categoria PS2 continua opcional e cria backup antes de editar o XML.

## Conclusão

A estrutura do port é compatível com o fluxo de integração do dArkOSRE-R36 observado: o menu chama um `.sh` em `/roms/ports`, o launcher usa o wrapper retrorun 64-bit, e o RetroArch fornece GL, udev, áudio, tela e hotkeys. Ainda não é possível garantir funcionamento na instalação mais atual sem testar no R36 físico ou receber a saída de `ldd --version`, `getconf GNU_LIBC_VERSION`, `file /usr/local/bin/retrorun`, `file /usr/local/bin/retroarch` e a listagem das bibliotecas GLES.

## Referências

[1]: https://github.com/southoz/dArkOSRE-R36 "dArkOSRE-R36 — código e rootfs auditados"

[2]: https://github.com/southoz/dArkOSRE-R36/blob/main/files/ROOTFS/etc/emulationstation/es_systems.cfg "Configuração de sistemas do EmulationStation"

[3]: https://github.com/southoz/dArkOSRE-R36/blob/main/files/ROOTFS/usr/local/bin/dreamcast.sh "Wrapper retrorun do dArkOS para Dreamcast"

[4]: https://github.com/southoz/dArkOSRE-R36/blob/main/files/ROOTFS/usr/local/bin/perfmax "Preparação de desempenho do dArkOS"

[5]: https://github.com/southoz/dArkOSRE-R36/releases "Releases do dArkOSRE-R36"
