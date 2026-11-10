# CONTRATO CORE ↔ VISUAL

## Princípio único
Core não conhece Visual. Nunca.
Visual não decide regra. Nunca.

## Core emite (sinais)
- tube_selected(index)
- tube_deselected(index)
- pour_started(from, to)
- pour_finished(from, to, color)
- pour_invalid(from, to, reason)
- tube_completed(index, color)
- level_won(moves_total)
- state_changed(state_dict) — estado bruto para desenhar

## Visual envia (intenções)
- select_tube(index)
- deselect()
- pour_tube(from, to)
- undo()
- restart()

## Proibições explícitas
Core: não importa cena, não chama get_node, não anima,
      não sabe que existe tela.
Visual: não valida regra, não assume sucesso, não
        inventa estado.

## Teste do contrato
Rodar core/tests/ no terminal, sem abrir Godot.
Se passar, contrato honrado.
Se precisar da cena para testar regra, contrato vazou.

## Consequência prática
Se apagar visual/, o core/ continua rodando no terminal
e os testes passam. Se não passar, é bug de arquitetura —
não bug de código.
