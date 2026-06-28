Contexto: estou iniciando o projeto `serverless-dataviz`, o primeiro de uma
trilha de aprendizado técnico que defini previamente. Ele mora em
`programacao/serverless-dataviz` e é deliberadamente um SANDBOX: o objetivo
não é responder a uma pergunta de pesquisa, e sim dominar a capacidade de
publicar visualizações de dados interativas SEM SERVIDOR (sem backend, sem
hosting pago), para depois embutir essa capacidade nos meus projetos de
pesquisa em R.

Stack: R/tidyverse, RStudio, GitHub. Alvo de publicação: GitHub Pages.
Critério de sucesso da primeira etapa: uma página interativa que carrega e
roda inteiramente no navegador.

O que eu quero desta primeira sessão, nesta ordem:

1. Antes de qualquer código, organize o panorama das rotas client-side em R
   hoje — Shinylive, webR (Quarto Live / OJS), Quarto Dashboards — deixando
   claro o que cada uma é e como se relacionam (algumas não são alternativas
   mutuamente exclusivas). Depois, comparativo crítico com prós, contras e
   limitações reais: peso de carregamento WASM, latência de inicialização,
   quais pacotes R simplesmente não rodam em WASM, o que costuma quebrar.
   Termine com uma recomendação para o caso "dataviz interativa publicada no
   GitHub Pages".

2. Em seguida, monte um exemplo mínimo ponta a ponta, criando os arquivos de
   fato. Use um dataset pequeno e público — de preferência do meu domínio
   (ex.: uma série temporal do DATASUS ou um indicador municipal simples);
   se for didaticamente melhor começar com um dataset embutido, justifique.

3. Especifique o passo de publicação (build + deploy no GitHub Pages),
   incluindo todos os arquivos de configuração necessários.

Restrições: seja crítico e direto; aponte as ciladas (sobretudo
incompatibilidades com WASM) antes que eu esbarre nelas. Não infle o escopo —
quero um primeiro entregável completo e funcional, não cobertura exaustiva.