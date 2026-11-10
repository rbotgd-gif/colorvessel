# PLAYBOOK — Color Vessel Puzzle (v1.0.1)

Projeto: Piloto (Fábrica de Jogos IA).
Engine: Godot 4.7.2.stable.official [ed1daf0b1]
Linguagem: GDScript puro no Core (sem Node). Testes via SceneTree headless.
Orçamento: R$135/mês (Claude Pro + Gemini Plus).
Prazo de teste da fábrica: 3 meses (nov/dez/jan). Fev/2027 avalia.
Carga horária: 14h/semana (2h/dia).
Estrutura: repo `colorvessel` + `docs/legacy/` como referência.

## 3 Regras Duras
1. Um dono por decisão. D1 decide prioridade e rumo. O resto vem em decision brief recomendado.
2. Nada entra no repo sem checklist de PR.
3. Uma coisa de cada vez por 30 dias. Zero ideia nova, zero mecânica nova, zero feature nova.

## Escopo do Primeiro Ciclo
- 5 fases, 1 mecânica (verter), 0 mecânicas especiais.
- 1 nível (N1 Base).
- Arte funcional (formas e cores). Sem freelancer.
- 2 papéis ativos (P1 Produção + E1 Engenharia). A1 Auditoria quando chamado. D1 Direção sempre.

## Corte Congelado (30 dias)
- 90 fases → 5 fases.
- 7 níveis → 1 nível.
- 4 mecânicas especiais → 0 no código (apenas em docs/legacy).
- n8n, Docs-as-Code, Brainstorm, Automação → 0.
- 12 ideias do estacionamento antigo → congeladas (não ler).

## Contrato de Arquitetura
Core não conhece Visual. Visual não decide regra. Detalhes em docs/contrato-core-visual.md.

## Pergunta que Fecha o Ciclo
Não é "o jogo está bom?". É "a fábrica produziu algo jogável no prazo?". Se não: o problema é o processo, não o jogo.
