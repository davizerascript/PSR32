# PSR32 — Port experimental de PlayStation 2 para R36S/R36H

Este é o **PSR32**, um port ARM64 experimental para portáteis RK3326 com ArkOS/dArkOS. Ele é baseado no código-fonte de um emulador open-source de PlayStation 2, integrado ao frontend libretro para usar o vídeo, áudio, controles e hotkeys fornecidos pelo sistema.

## Projeto e contato

O nome do projeto é **PSR32**. Para acompanhar o projeto ou entrar em contato, visite o Instagram [@Melo._.071](https://www.instagram.com/Melo._.071/).

O projeto não redistribui jogos, imagens de disco, BIOS proprietária ou firmware. A atribuição do código upstream e as licenças dos componentes estão em [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md) e na pasta [`LICENSES/`](LICENSES/).

## Download e instalação offline

Baixe `ps2-rk3326.zip` na página **Releases** deste repositório usando um computador ou celular. Depois copie o ZIP para o cartão microSD do R36S/R36H. O R36S não precisa ter Wi-Fi, conta PortMaster ou conexão de rede para instalar e executar este port.

Extraia o conteúdo do ZIP diretamente em `/roms/ports/` no cartão. Os arquivos `PS2-RK3326.sh` e `Install PS2 RK3326.sh` precisam ficar diretamente dentro de `/roms/ports/`; mantenha a subpasta `ps2rk3326/` ao lado deles. Não coloque os dois scripts dentro de uma segunda pasta, porque o EmulationStation do dArkOS procura os scripts de Ports nesse nível. O PortMaster é apenas uma forma opcional de organizar ports; este pacote também pode ser instalado manualmente por cópia no cartão.

Depois, coloque suas próprias imagens legalmente obtidas em `/roms/ps2`. O launcher aceita `.iso`, `.chd`, `.cso`, `.cue/.bin` e `.elf` (incluindo homebrews de PlayStation 2 como `dungeon_game.elf`). O instalador registra todas essas extensões no EmulationStation.

## Instalação com um clique no menu

Com os dois scripts diretamente em `/roms/ports/`, abra **Ports** no menu principal e clique em **Install PS2 RK3326.sh**. Esse único arquivo SH executa localmente o instalador, cria `/roms/ps2`, faz backup de `/etc/emulationstation/es_systems.cfg`, adiciona a categoria **PlayStation 2** e reinicia o EmulationStation. Não é necessário SSH, Wi-Fi, conta do PortMaster ou download durante esse processo.

Se você já instalou uma revisão anterior, apenas substitua os arquivos do port no cartão e clique novamente em **Install PS2 RK3326.sh**. O instalador detecta a entrada `ps2` antiga sem `.elf`, cria outro backup datado e migra somente esse bloco para a configuração nova, preservando os demais sistemas. Se a entrada já contém `.elf`, a execução é idempotente e não a duplica.

Depois do reinício, as imagens em `/roms/ps2` aparecerão na categoria **PlayStation 2**. Ao clicar em uma imagem, o EmulationStation passará o caminho dela ao `PS2-RK3326.sh`, que abrirá o retrorun/RetroArch já carregando o jogo diretamente.

O instalador não modifica DTB ou `boot.ini` e não reinstala o firmware. Para remover a categoria, restaure o backup correspondente e reinicie o EmulationStation. A revisão anterior omitia `.elf` no XML; por isso, instalar o pacote novo e repetir o clique é necessário para atualizar uma entrada PS2 que já existia.

## Wi-Fi e downloads durante a execução

O port não precisa de Wi-Fi para iniciar ou executar os jogos. Depois que o ZIP for baixado em outro dispositivo e copiado para o cartão, não há download obrigatório durante a instalação ou execução. O R36S pode permanecer completamente offline.

Não é necessário copiar uma BIOS externa: o código-fonte upstream utilizado pelo core implementa uma camada HLE integrada. Isso não autoriza o uso de jogos ou arquivos que o usuário não tenha direito de utilizar.

## Compatibilidade dArkOS

A estrutura foi comparada diretamente com o snapshot `03082026` do projeto [dArkOSRE-R36](https://github.com/southoz/dArkOSRE-R36). O menu Ports usa scripts `.sh` em `/roms/ports`; os wrappers oficiais para cores 64-bit chamam `/usr/local/bin/retrorun` com `/home/ark/.config/retrorun.cfg`; e o RetroArch 64-bit auditado usa `video_driver = "gl"`, `input_driver = "udev"`, áudio `alsathread` e viewport 640×480.

O launcher segue esse fluxo, exporta `SDL_VIDEO_EGL_DRIVER=libEGL.so`, reconhece os perfis DTB comuns do RK3326/R36 e deixa o retrorun/RetroArch escolher o backend SDL do firmware. Quando nenhum mapa externo é fornecido, ele usa um fallback offline comprovado para o GO-Super Gamepad: A=b1, B=b0, X=b2, Y=b3, D-pad=b8..b11, L1/R1=b4/b5, L2/R2=b6/b7, Select/Start=b12/b13, analógicos=a0..a3 e cliques L3/R3=b14/b15. A entrada PS2 gerada pelo instalador usa a mesma moldura oficial `sudo perfmax %GOVERNOR% %ROM%; nice -n -19 ...; sudo perfnorm`; o launcher não força `SDL_VIDEODRIVER`, KMSDRM, VSync ou uma placa DRM específica. O checkout do dArkOS não contém o binário retrorun nem as bibliotecas EGL/GLES da imagem final. Por isso, o mapa e o ambiente estão preparados para instalação offline, mas o carregamento final ainda deve ser confirmado no aparelho real, principalmente pela glibc e pelo contexto OpenGL ES 3.

## Controles

O core usa o padrão libretro de controle compatível com DualShock 2: direcional, dois analógicos, Select, Start, Square, Triangle, Circle, Cross, L1/L2/L3 e R1/R2/R3. O launcher mantém o mapa GO-Super no pacote, sem depender de download do PortMaster. O core também registra callbacks, máscara de botões e valores dos quatro eixos no `log.txt`, o que permite saber se o problema está no frontend ou no mapeamento. O mapa é direcionado ao perfil físico confirmado no dArkOS; outras revisões de controle podem exigir ajuste no RetroArch.

## Revisão atual e diagnóstico da tela preta

O core da revisão atual foi recompilado para negociar **OpenGL ES 3.1** com o enum libretro versionado `RETRO_HW_CONTEXT_OPENGLES_VERSION` (em vez do enum fixo `RETRO_HW_CONTEXT_OPENGLES3`, que representa GLES 3.0). A mudança é direcionada ao perfil Mali-G31/RK3326, no qual a disponibilidade de GLES 3.1 é uma expectativa mais conservadora; os shaders do core já usam GLSL ES 3.00. O binário anterior foi observado no teste com Need for Speed Underground 2 ficando aproximadamente nove segundos em tela preta e retornando ao menu. A revisão atual é uma tentativa técnica de corrigir a inicialização do contexto; **não há afirmação de que NFSU2 esteja compatível ou rápido**.

O perfil inicial usa resolução interna 1×, OpenGL ES 3.1 e apresentação ajustada à tela do portátil. O core solicita rotação libretro 0 para não herdar uma orientação de 90 graus de uma sessão anterior; a orientação KMS/DRM definitiva continua sendo responsabilidade do dArkOS/retrorun, selecionada pelo `DEVICE_NAME=RG351MP`. O R36S/R36H não é uma plataforma oficialmente suportada pelo emulador upstream. Jogos 3D pesados podem apresentar lentidão, glitches gráficos, áudio irregular ou não iniciar; não existe promessa de taxa de quadros.

A versão foi testada em um ambiente que simula o dArkOSRE: compilação ARM64 do core revisado, ABI máxima GLIBC_2.36, símbolos libretro, propagação do launcher para um retrorun simulado, mapa offline, migração do XML e instalação repetida sem duplicação. No R36S, o projeto já deu sinal de vida, indicando que o core iniciou no hardware. Esse sinal não equivale a uma certificação de todos os jogos: ainda dependem de confirmação específica o FPS, frame pacing, áudio, temperatura, RAM, hotkeys, save states, compatibilidade de cada ISO/CHD e desempenho 3D.

Se o jogo ainda retornar ao menu, abra **Ports** novamente e copie o arquivo `/roms/ports/ps2rk3326/log.txt` do cartão para um computador ou celular. O launcher agora registra a arquitetura, o caminho e o tamanho da ROM, o core, as dependências ELF detectáveis, as variáveis SDL disponíveis e `emulator_exit_status`; esse arquivo é indispensável para distinguir falha de glibc, biblioteca/contexto GLES, retrorun ou boot do jogo. Se `log.txt` não existir, copie também `/roms/ports/ps2rk3326/install.log`: ele mostra se o instalador foi executado, qual `es_systems.cfg` ele tentou alterar e qual foi seu código de saída. Em dArkOS, os helpers opcionais do PortMaster podem deixar `DEVICE_INFO_VERSION` sem valor; o launcher agora os lê com `nounset` temporariamente desativado, evitando que esse campo opcional encerre o processo antes do retrorun.

## Conteúdo

| Arquivo | Função |
|---|---|
| `PS2-RK3326.sh` | Launcher local; também segue a convenção de Ports/PortMaster. |
| `Install PS2 RK3326.sh` | Atalho para o instalador da categoria dedicada. |
| `ps2rk3326/ps2rk3326_libretro.so` | Core ARM64 compilado para Cortex-A35/ARMv8-A. |
| `ps2rk3326/install_ps2_system.sh` | Instalador opcional do EmulationStation. |
| `port.json` e `gameinfo.xml` | Manifesto e metadados do PortMaster. |
| `THIRD_PARTY_NOTICES.md` e `LICENSES/` | Atribuição e licenças. |

Para diagnóstico de uma instalação que não inicia, veja [`darkos-compatibility-audit.md`](https://github.com/davizerascript/PSR32/blob/main/darkos-compatibility-audit.md) no repositório ou execute no R36:

```sh
ldd --version
getconf GNU_LIBC_VERSION
uname -m
file /usr/local/bin/retrorun
file /usr/local/bin/retroarch
ls -l /usr/lib*/libGLESv2.so* /lib*/libGLESv2.so* 2>/dev/null
```
