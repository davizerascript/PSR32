# PSR32 — build experimental de desempenho

Esta build é somente para teste no R36S/R36H. Ela não substitui a release estável e não deve ser instalada por cima sem backup.

## Alterações

A configuração experimental solicita multiplicador de resolução interna de **0,5×**, alvo de **30 FPS** pelo parâmetro nativo `ps2.limitframerate` e contador de FPS do retrorun no canto da tela por meio de `retrorun_fps_counter = true`.

O core expõe `renderer.opengl.resfactor` e a implementação atual do renderer usa a escala de framebuffer. O arquivo também registra `play_res_multi = 0.5x` como fallback de compatibilidade; se uma versão do core não reconhecer esse nome, ele será ignorado e `renderer.opengl.resfactor` continuará sendo a opção principal.

## Limitações

O launcher não consegue provar, sem executar no R36S físico, que toda versão do retrorun aplica opções de core da mesma forma. O contador deve aparecer se o wrapper aceitar `retrorun_fps_counter`; o limitador de 30 FPS depende do core consumir `ps2.limitframerate`. Caso o core ignore esse valor, o jogo poderá continuar em 60 FPS, mas a configuração não deve causar erro de inicialização.

A versão estável do core permanece intacta. Para rollback, remova os arquivos de teste e restaure o launcher/configuração da release anterior. Não apague saves nem imagens de jogo.
