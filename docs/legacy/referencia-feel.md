# LEGADO: REFERÊNCIA DE FEEL (O que funcionou)

Atenção: Isto é referência de design, NÃO é código para copiar. 
O código novo deve ser escrito do zero seguindo o contrato Core/Visual.

## O que era o projeto antigo (v3)
O jogo parecia "só ok" porque usava um Tween linear de 0.18s para verter o líquido.

## O que resolvemos na época (e deve ser mantido no v4)
1. **Curva de Animação:** Trocar Linear por Tween com `ease-out` (acelera e freia).
2. **Micro-pausa:** Pausar 50ms após o término do verter antes de liberar o próximo input.
3. **Input Buffer:** Se o jogador clicar no próximo tubo enquanto a animação atual roda, enfileirar a jogada. Não ignorar o clique.
4. **Derretimento (Gelatina):** O bloco sólido vira líquido ao ser selecionado. 
5. **Áudio:** Som em camadas (início, loop, fim, clique de conclusão).

## Como isso se aplica no v4
O Core não vai animar nada. O Core vai calcular "verteu". 
O Visual vai ouvir o sinal `pour_started` e aplicar o Tween (ease-out). 
O Visual vai esperar o Tween acabar e enviar `pour_finished` para o Core liberar a próxima jogada.
