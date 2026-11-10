# CHECKLIST DE PR

Todo PR precisa ter, no corpo:

- [ ] Etapa que atende (ex: Etapa 3)
- [ ] O que mudou (1-3 linhas)
- [ ] Como testar (comando ou passo-a-passo)
- [ ] Evidência de teste (saída do terminal, print,
      ou "joguei e funciona")
- [ ] Arquivos tocados, separados em core/ e visual/
- [ ] Confirmação: "Core não importa Visual" /
      "Visual não decide regra"

## Bloqueia merge
- PR sem evidência de teste
- PR que mexe em core e visual no mesmo commit
- PR com código comentado sem "TODO:" justificado
- PR com mais de 200 linhas alteradas (quebrar em dois)

## Aprovação
- D1 aprova
- A1 audita quando toca contrato ou regra
