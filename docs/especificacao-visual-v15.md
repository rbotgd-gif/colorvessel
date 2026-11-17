# Especificação Visual & Arquitetural V1.5 — Color Vessel Puzzle

## 1. Visão Geral
Esta especificação consolida a evolução do Color Vessel Puzzle para a versão V1.5, integrando o estilo visual **Juicy Glossy** (bordas douradas, gradientes suaves, pílulas, badges e ícones vetoriais/fontes customizadas) com a temática original de **Geladeira Térmica** (fundos gélido e quente, tubos de vidro e blocos de gelatina).

## 2. Decisões Estruturais & Diretrizes do Fundador (D1)
1. **Isolamento Core/Visual:** Mantido rigorosamente. Nenhuma lógica de economia (moedas, vidas) ou poderes reside em nós visuais; toda regra de negócio do meta-game habita classes puras em `core/src/`.
2. **Viewport & Escala:** Fixado em retrato (`720x1280`) com stretch mode `canvas_items` e aspect `keep`.
3. **Tipografia:** Uso de fonte OFL arredondada (`Fredoka Bold`) em `visual/assets/fonts/` para máxima fidelidade tipográfica.
4. **Animações & Testes:** Animações de despejo em arco e UI possuem bypass automático em modo headless para garantir que os testes automatizados (`core/tests/` e `visual/tests/`) executem sem falhas ou atrasos.
5. **Economia & Vidas:**
   - Perda de vida ocorre apenas ao abandonar ou reiniciar uma fase em andamento.
   - Vida infinita ativa (30 minutos via timestamp Unix) impede qualquer consumo de vidas.
   - Loja 100% simulada (incluindo bônus de vida infinita e baú de prêmio a cada 5 fases).
   - Abas 4 (Conquistas) e 5 (Perfil) da barra inferior marcadas como "Em breve".
6. **Poderes do Jogador:** Desfazer (histórico de estados do tabuleiro), Dica (buscada via Solucionador BFS) e +1 Tubo (adicionar tubo auxiliar).

## 3. Plano de Execução em Fases
- **Fase 1:** Fundação & Design System (Viewport retrato, extração de `Main` para `TabuleiroView`, CVTokens, CVTema, fontes, componentes base).
- **Fase 2:** Core dos Poderes & Sinais (Histórico de desfazer, dica, +1 tubo, sinais do contrato).
- **Fase 3:** Gameplay HUD & Dock de Poderes.
- **Fase 4:** Animação de Despejo Fluida (Arco, inclinação, jato, tubo completo).
- **Fase 5:** Core de Meta & Persistência (Economia, vidas, infinito, salvamento).
- **Fase 6:** Modais (Vitória, Sem Movimentos, Mais Vidas).
- **Fase 7:** Hub Principal & Navegação (ScreenManager, Barra superior, Botão central Nível X, Abas inferiores).
- **Fase 8:** Loja Simulada.
- **Fase 9:** Mapa de Progressão.
- **Fase 10:** Polimento Final, QA & Testes.
