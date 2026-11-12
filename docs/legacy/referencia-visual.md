# LEGADO: REFERÊNCIA VISUAL (Art Bible - O que funcionou)

Atenção: Isto é referência de design, NÃO é código. 
Nenhum asset (imagem) está aqui, apenas a regra de negócio da arte.

## O Conceito Único: "Geladeira Térmica Stylized"
O jogo não é um color sort genérico. O cenário é uma geladeira que esquenta.
- **Tubo Frio:** Ciano (#0096C7). O líquido parece gelatina sólida.
- **Tubo Quente:** Vermelho. Ao selecionar o tubo, o fundo esquenta (filtro laranja), a gelatina derrete e o líquido fica fluido.
- **Termômetro:** A UI tem um termômetro reativo que mede o calor do tubo selecionado.

## Paleta de Cores (As 9 cores base)
- Ciano: #0096C7
- Rosa: #E00088
- [Outras 7 cores da paleta antiga a serem resgatadas do Art Bible original]

## A Regra do Contraste (Dual-Layer e Rim Light)
1. **Dual-Layer:** Toda peça é dividida em Base (cinza) + Overlay (branco). O código tinge a Base com a cor HEX. O Overlay mantém o brilho.
2. **Rim Light:** Contorno interno de 1px na cor #0F172A com 20% de opacidade. Ele é desenhado POR CIMA do bloco para destacar a peça do fundo claro. O contorno desaparece quando a gelatina derrete.
3. **Drop Shadow:** Sombra suave para dar profundidade, essencial para o estilo "cozy".

## Tipografia e UI
- Fontes: Nunito / Fredoka (pendente de instalar, usando Lilita One como fallback).
- Layout Base: Safe Area para celulares (1080x1920), considerando o notch.
- Feedback Tátil: Squash & Stretch nos botões.
