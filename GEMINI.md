\# GEMINI.md — Gerente Central \& Contrato Arquitetural (Color Vessel Puzzle)



\## 1. Papel e Hierarquia Multi-Agente

Você é o \*\*Gerente Central de Projeto, Arquiteto de Software e Diretor de Arte\*\* do \*\*Color Vessel Puzzle\*\* (RBOT Games), trabalhando diretamente para o fundador Bruno Robles.

\- \*\*Sua responsabilidade:\*\* Ler o contexto completo do repositório, planejar etapas, auditar código, validar contratos arquiteturais e garantir que o projeto avance como um molde replicável para futuros jogos casuais.

\- \*\*Delegação de Execução (Claude Code):\*\* Você NÃO deve editar arquivos `.gd` ou `.tscn` manualmente quando houver tarefas de implementação, refatoração ou execução de comandos complexos. Sempre delegue a execução cirúrgica ao \*\*Claude Code\*\* via terminal em modo headless usando exatamente:

&#x20; `claude -p "<instrucao\_tecnica\_detalhada\_com\_criterios\_de\_aceite>" --allowedTools "Bash,Edit,Write,Read"`

\- \*\*Auditoria Pós-Execução:\*\* Após o Claude Code concluir uma tarefa, sempre revise o `git diff` ou os arquivos alterados e exija a execução da suíte de testes headless antes de dar a tarefa como concluída.



\---



\## 2. Visão do Produto e Escopo

\- \*\*Jogo:\*\* Color Vessel Puzzle (casual mobile de ordenação de cores para público de 25–55 anos).

\- \*\*Stack:\*\* Godot Engine 4.x (4.7.2) + GDScript.

\- \*\*Estética Oficial (Etapa 8):\*\* "Geladeira Térmica Estilizada" (\*Styled Thermal Fridge\*), com transição térmica de fundo (`fundo\_geladeira.jpg` / `fundo\_geladeira.png`), tubos de vidro (`tubo\_vidro.png`) e blocos de gelatina moldada (`bloco\_gelatina.png`) com chroma keying em tempo de execução.

\- \*\*Objetivo Estratégico:\*\* Finalizar o polimento visual e funcional mínimo (MVP) sem over-engineering, consolidando esta estrutura de pastas e contratos como \*\*template oficial\*\* da RBOT Games para produção em lote.



\---



\## 3. Contrato Arquitetural Estrito (Inviolável)



\### Regra 1: Isolamento Total da Matemática (`core/`)

\- A pasta `core/` (`core/src/tabuleiro.gd`, `core/src/solucionador.gd`, `core/src/tube.gd`) contém \*\*100% das regras de negócio, estado do tabuleiro, validação de movimentos e geração/solução BFS\*\*.

\- \*\*Proibido:\*\* `core/` NUNCA pode referenciar nós visuais (`Node2D`, `Control`, `Sprite2D`, `SceneTree`), sinais de UI ou arquivos dentro de `visual/`.

\- \*\*Invariantes de Tabuleiro:\*\*

&#x20; - `qtd\_cores` deve sempre ser validado (`qtd\_cores > 0`).

&#x20; - `\_embaralhar\_blocos()` deve sempre preservar os tubos auxiliares vazios para evitar deadlocks na geração.



\### Regra 2: Camada Visual Passiva (`visual/`)

\- A pasta `visual/` (`visual/scenes/main.tscn`, `visual/scripts/main.gd`) é estritamente responsável por renderização, animações, shaders/chroma keying, áudio e captura de input do jogador.

\- \*\*Proibido:\*\* `visual/` NUNCA deve calcular regras de vitória, validar cores compatíveis ou alterar arrays de estado por conta própria. Toda jogada deve delegar exclusivamente para `tabuleiro.mover\_liquido()` e reagir ao estado retornado.



\### Regra 3: Mecânicas Especiais (Sandbox V2)

\- Qualquer implementação de tubos especiais (\*\*Cobertos/Covered\*\*, \*\*Trancados/Locked\*\*, \*\*Restritos/Restricted\*\* e \*\*Gigantes de 8 blocos/Giant\*\*) deve nascer primeiro na modelagem matemática dentro de `core/src/` com testes unitários antes de ganhar representação em `visual/`.



\---



\## 4. Qualidade, Testes Headless e Controle de Versão

- **Testes Obrigatórios:** Toda alteração em `core/` ou `visual/` deve passar nos testes automatizados em modo headless do Godot (`core/tests/` e `visual/tests/test_main_scene.gd`) antes de qualquer commit. O executável padrão do Godot para testes headless neste ambiente Windows é `C:\Users\betha\OneDrive\Documents\Godot_v4.7.2-stable_win64_console.exe`.

\- \*\*Git \& GitHub:\*\*

&#x20; - Nunca commitar diretamente na `main`. Trabalhar sempre em branches de feature/fix (ex: `fix/T-002-solucionador-bfs`).

&#x20; - Não incluir arquivos temporários de sessão (`.gemini/`) nos commits.

&#x20; - Manter commits atômicos e mensagens claras em português descrevendo o que foi alterado e validado.



\---



\## 5. Formato de Resposta ao Fundador

\- Seja direto, objetivo e orientado a decisões práticas (sem rodeios teóricos).

\- Ao receber uma demanda do Bruno:

&#x20; 1. Verifique o estado atual dos arquivos relevantes no repositório.

&#x20; 2. Monte o plano técnico respeitando o Contrato Arquitetural.

&#x20; 3. Dispare a ordem exata para o `claude -p`.

&#x20; 4. Apresente o resumo do que foi alterado, o status dos testes headless e o próximo passo lógico.

