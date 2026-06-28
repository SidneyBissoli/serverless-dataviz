# serverless-dataviz

## O que é este projeto
Sandbox de aprendizado. Objetivo: dominar a publicação de visualizações de
dados interativas SEM SERVIDOR (sem backend, sem hosting pago), para depois
embutir essa capacidade nos meus projetos de pesquisa em R. Não é um projeto
de pesquisa — não há pergunta substantiva a responder aqui.

## Stack e alvo
- R / tidyverse, Quarto.
- Rotas a explorar: Shinylive, webR (Quarto Live), Quarto Dashboards.
- Publicação: GitHub Pages.
- Critério de sucesso da primeira etapa: uma página interativa que carrega e
  roda inteiramente no navegador.

## Convenções de código
- Pipe nativo `|>` (não `%>%`).
- `str_c()` em vez de `paste0()`.
- `theme_bw()` como padrão em ggplot2.
- Comentários de código em inglês.
- Números no padrão brasileiro (vírgula decimal, ponto de milhar) nos outputs.

## Postura
- Priorizar um primeiro entregável completo e funcional sobre cobertura
  exaustiva. Não inflar escopo.
- Ser crítico e direto; apontar ciladas técnicas antes que eu esbarre nelas,
  em especial incompatibilidades de pacotes R com WASM.