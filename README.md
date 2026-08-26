# Port experimental de PlayStation 2 para R36S/R36H

Este é um port ARM64 experimental para portáteis RK3326 com ArkOS/dArkOS. Ele é baseado no código-fonte de um emulador open-source de PlayStation 2, integrado ao frontend libretro para usar o vídeo, áudio, controles e hotkeys fornecidos pelo sistema.

O projeto não redistribui jogos, imagens de disco, BIOS proprietária ou firmware. A atribuição do código upstream e as licenças dos componentes estão em [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md) e na pasta [`LICENSES/`](LICENSES/).

## Download e instalação

Baixe `ps2-rk3326.zip` na página **Releases** deste repositório. A instalação recomendada é abrir o PortMaster no R36S/R36H e instalar o ZIP por sua interface. Também é possível extrair o conteúdo do ZIP no cartão, mantendo a pasta do port em `/roms/ports/ps2rk3326/`.

Depois da instalação, coloque suas próprias imagens de jogos legalmente obtidas em `/roms/ps2`. O launcher aceita `.iso`, `.chd`, `.cso` e `.cue/.bin`.

No menu principal, abra **Ports** e selecione **PS2-RK3326**. O launcher inicia diretamente a imagem selecionada pelo `retrorun` 64-bit do dArkOS quando ele está disponível; caso contrário, usa RetroArch como fallback.

## Categoria dedicada no menu

Se quiser que os jogos apareçam em uma categoria separada **PlayStation 2**, execute uma vez por SSH, depois de instalar o port:

```sh
bash "/roms/ports/ps2rk3326/ps2rk3326/install_ps2_system.sh"
sudo systemctl restart emulationstation
```

O instalador cria um backup datado de `/etc/emulationstation/es_systems.cfg`, não modifica DTB ou `boot.ini` e não reinstala o firmware. Para remover a categoria, restaure o backup correspondente e reinicie o EmulationStation.

## Wi-Fi e downloads durante a execução

O port não precisa de Wi-Fi para iniciar ou executar os jogos. Depois que o ZIP estiver no cartão e as imagens legais estiverem em `/roms/ps2`, não há download obrigatório durante a execução. O Wi-Fi só seria necessário para baixar o ZIP diretamente no aparelho ou para usar serviços externos do próprio sistema.

Não é necessário copiar uma BIOS externa: o código-fonte upstream utilizado pelo core implementa uma camada HLE integrada. Isso não autoriza o uso de jogos ou arquivos que o usuário não tenha direito de utilizar.

## Compatibilidade dArkOS

A estrutura foi comparada diretamente com o snapshot `03082026` do projeto [dArkOSRE-R36](https://github.com/southoz/dArkOSRE-R36). O menu Ports usa scripts `.sh` em `/roms/ports`; os wrappers oficiais para cores 64-bit chamam `/usr/local/bin/retrorun` com `/home/ark/.config/retrorun.cfg`; e o RetroArch 64-bit auditado usa `video_driver = "gl"`, `input_driver = "udev"`, áudio `alsathread` e viewport 640×480.

O launcher segue esse fluxo, exporta `SDL_VIDEO_EGL_DRIVER=libEGL.so`, preserva `ESUDO` e reconhece os perfis DTB comuns do RK3326/R36. O checkout do dArkOS não contém o binário retrorun nem as bibliotecas EGL/GLES da imagem final. Por isso, a interface está alinhada ao sistema, mas o carregamento final ainda deve ser confirmado no aparelho real, principalmente pela glibc e pelo contexto OpenGL ES 3.

## Controles

O core usa o padrão libretro de controle compatível com DualShock 2: direcional, dois analógicos, Select, Start, Square, Triangle, Circle, Cross, L1/L2/L3 e R1/R2/R3. O dArkOS/PortMaster fornece o mapeamento SDL/udev da variante física. Se algum botão estiver invertido ou ausente, ajuste-o no menu de controles do RetroArch; não há um mapa físico universal porque existem várias revisões de R36S/R36H.

## Desempenho e limitações

O perfil inicial usa resolução interna 1×, OpenGL ES 3 e apresentação ajustada à tela do portátil. O R36S/R36H não é uma plataforma oficialmente suportada pelo emulador upstream. Jak and Daxter pode apresentar lentidão, glitches gráficos, áudio irregular ou não iniciar; não existe promessa de taxa de quadros.

O sandbox confirmou a compilação ARM64, o carregamento do core via QEMU, os exports libretro, o launcher e o instalador XML. Ainda não foram medidos no aparelho físico FPS, frame pacing, áudio, temperatura, RAM, hotkeys, save states, compatibilidade de ISO/CHD ou desempenho 3D.

## Conteúdo

| Arquivo | Função |
|---|---|
| `PS2-RK3326.sh` | Launcher PortMaster. |
| `Install PS2 RK3326.sh` | Atalho para o instalador da categoria dedicada. |
| `ps2rk3326/ps2rk3326_libretro.so` | Core ARM64 compilado para Cortex-A35/ARMv8-A. |
| `ps2rk3326/install_ps2_system.sh` | Instalador opcional do EmulationStation. |
| `port.json` e `gameinfo.xml` | Manifesto e metadados do PortMaster. |
| `THIRD_PARTY_NOTICES.md` e `LICENSES/` | Atribuição e licenças. |

Para diagnóstico de uma instalação que não inicia, veja [`darkos-compatibility-audit.md`](https://github.com/davizerascript/ps2-rk3326-port/blob/main/darkos-compatibility-audit.md) no repositório ou execute no R36:

```sh
ldd --version
getconf GNU_LIBC_VERSION
uname -m
file /usr/local/bin/retrorun
file /usr/local/bin/retroarch
ls -l /usr/lib*/libGLESv2.so* /lib*/libGLESv2.so* 2>/dev/null
```
