# Avisos de terceiros

Este repositório distribui um binário baseado no código-fonte de um emulador open-source de PlayStation 2. A atribuição upstream, o aviso de copyright e as condições de redistribuição estão em `LICENSES/UPSTREAM-EMULATOR-LICENSE.txt` e também podem ser consultados no [repositório upstream](https://github.com/jpd002/Play-).

O core foi compilado com componentes do Framework, CodeGen, libchdr e bibliotecas auxiliares. As cópias das licenças correspondentes estão em `LICENSES/`:

| Componente | Arquivo de licença |
|---|---|
| Código-fonte upstream do emulador | `UPSTREAM-EMULATOR-LICENSE.txt` |
| Framework gráfico e utilitários | `FRAMEWORK-LICENSE.txt` |
| CodeGen/JIT | `CODEGEN-LICENSE.txt` |
| libchdr e dependências | `LIBCHDR-LICENSE.txt`, `LIBCHDR-ZLIB-LICENSE.txt`, `LIBCHDR-ZSTD-LICENSE.txt`, `LZMA-LICENSE.txt` |
| zlib, zstd, xxHash e bzip2 | `ZLIB-LICENSE.txt`, `ZSTD-LICENSE.txt`, `XXHASH-LICENSE.txt`, `BZIP2-LICENSE.txt` |
| GLEW e nlohmann-json | `GLEW-LICENSE.txt`, `NLOHMANN-JSON-LICENSE.txt` |

O port, os launchers e o instalador do EmulationStation são a camada de integração deste repositório. Eles não incluem jogos, imagens de disco, BIOS ou firmware proprietário. O usuário deve utilizar somente conteúdo que tenha o direito de usar.
