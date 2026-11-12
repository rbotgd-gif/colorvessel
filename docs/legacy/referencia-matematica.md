# LEGADO: REFERÊNCIA MATEMÁTICA (Regras e Gerador)

Atenção: Isto documenta a lógica do cérebro do jogo antigo. O código novo do Core deve 
ser escrito do zero, mas as regras matemáticas abaixo são a fonte da verdade do design.

## 1. Regras das Mecânicas Especiais (O que validamos)
- **Coberto:** O jogador não vê a cor. Ela é revelada ao selecionar o tubo ou quando o tubo de cima é esvaziado.
- **Trancado:** O tubo não aceita líquido até que uma cor inteira (4 blocos) seja completada em outro lugar.
- **Restrito:** O tubo só aceita uma cor específica (com animação de shake se errar).
- **Gigante:** Tubo com capacidade para 8 blocos (em vez de 4).
- *Regra de Ouro:* No projeto antigo, o gerador era proibido de criar fases que já começavam com um tubo completo (tirava o desafio).

## 2. O Gerador BFS (O que validamos)
O gerador de fases usa BFS (Busca em Largura) para garantir que a fase tem solução antes de entregá-la ao jogador.
- Ele cria 3 variantes para cada fase.
- Ele descarta imediatamente qualquer fase onde o BFS detecte "deadlock" (beco sem saída).

## 3. Curva Sawtooth (Dentes de Serra)
As fases não são lineares. Elas alternam:
- **Picos:** Fases difíceis (apenas 1 tubo vazio).
- **Alívios:** Fases mais tranquilas (2 ou mais tubos vazios).
Isso evita a fadiga mental do jogador.

## 4. Escala DD (Dificuldade)
A régua matemática de dificuldade (DD) foi expandida para:
- Fácil, Médio, Difícil, Desafio
- Mestre: 40-79
- Lenda: 80-119
- Mítico: 120+
