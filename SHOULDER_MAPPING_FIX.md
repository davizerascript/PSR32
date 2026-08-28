# Correção do mapeamento L1/L2 e R1/R2

O teste físico informou que os dois shoulders de cada lado estavam invertidos: o botão físico L1 acionava L2, L2 acionava L1, R1 acionava R2 e R2 acionava R1.

O launcher `PS2-RK3326.sh` agora troca somente os rótulos semânticos SDL `leftshoulder`/`lefttrigger` e `rightshoulder`/`righttrigger`, preservando os índices físicos e a separação esquerda/direita. A correção fica ativa por padrão.

Se outra imagem do sistema já apresentar a ordem correta, inicie o launcher com a variável `PS2_SWAP_SHOULDERS=0` para desativar a troca. O fixture local confirmou:

```text
lefttrigger:b4
leftshoulder:b6
righttrigger:b5
rightshoulder:b7
SHOULDER_SWAP_TEST=PASS
```
