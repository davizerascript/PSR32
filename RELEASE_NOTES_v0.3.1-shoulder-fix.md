# PSR32 — revisão v0.3.1 shoulder fix

## Correção

Esta revisão corrige a inversão relatada no controle físico: L1 acionava L2, L2 acionava L1, R1 acionava R2 e R2 acionava R1. A correção troca somente os rótulos semânticos SDL `leftshoulder`/`lefttrigger` e `rightshoulder`/`righttrigger`, preservando os índices físicos e a separação entre esquerda e direita.

A troca fica ativa por padrão no `PS2-RK3326.sh`. Em uma imagem do sistema que já apresente a ordem correta, ela pode ser desativada com `PS2_SWAP_SHOULDERS=0` antes da execução.

## Validação

Os três scripts Bash passaram por verificação de sintaxe, o `gameinfo.xml` passou por parsing XML, as permissões executáveis foram preservadas e um fixture com configuração SDL conhecida confirmou:

```text
lefttrigger:b4
leftshoulder:b6
righttrigger:b5
rightshoulder:b7
SHOULDER_SWAP_TEST=PASS
```

O core não foi recompilado nesta revisão; somente o launcher e a documentação de entrada foram corrigidos. A validação física final continua dependendo do R36S/R36H real.

## Artefato

```text
PSR32-PS2-RK3326-shoulders-fixed-v0.3.1.zip
SHA-256: ac079d0c45362c2ca0df0bd44eae7c1c9bf3fc3dda3ae1c16f9fe76b773bb824
```
