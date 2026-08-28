# PSR32 v0.1.1-r36-input-screen

Esta revisão atualiza o port experimental de PlayStation 2 para R36S/R36H com foco na integração dArkOS, no controle e na orientação da tela.

## Correções

O launcher agora fornece um fallback offline para o GO-Super Gamepad quando nenhum mapa externo é fornecido. O mapa segue a configuração observada no dArkOS: A=b1, B=b0, X=b2, Y=b3, D-pad=b8..b11, L1/R1=b4/b5, L2/R2=b6/b7, Select/Start=b12/b13, analógicos a0..a3 e cliques L3/R3 b14/b15.

O core ARM64 foi recompilado a partir do checkout local do Play! com negociação OpenGL ES 3.1, correções no caminho de boot libretro, processamento de áudio em lote e diagnóstico de callbacks de input. O core também solicita rotação libretro zero; a seleção final de orientação KMS/DRM permanece com o dArkOS/retrorun e o perfil DEVICE_NAME=RG351MP.

O instalador continua offline, migra uma entrada PS2 antiga sem duplicar sistemas e registra `.iso`, `.mds`, `.isz`, `.chd`, `.cso`, `.cue` e `.elf`.

## Validação realizada

Foram executados testes de sintaxe shell, inspeção ELF AArch64, conferência de ABI máxima GLIBC_2.36, teste do launcher com retrorun falso e DTB R36S simulado, além de instalação e migração idempotentes do XML do EmulationStation.

Esses testes não substituem a execução no R36S/R36H físico. Ainda não foram medidos FPS, frame pacing, áudio, temperatura, consumo de RAM, hotkeys, save states, compatibilidade de cada ISO ou desempenho 3D real. A revisão não promete que Need for Speed Underground 2 ou outros jogos pesados iniciarão ou terão velocidade jogável.

## Instalação

Copie o conteúdo do ZIP para `/roms/ports/`, mantendo `PS2-RK3326.sh`, `Install PS2 RK3326.sh` e a pasta `ps2rk3326/` no mesmo nível. Execute o instalador pelo menu Ports, coloque imagens legalmente obtidas em `/roms/ps2` e reinicie o EmulationStation quando solicitado.
