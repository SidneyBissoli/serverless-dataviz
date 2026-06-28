# 01 — Panorama e decisão de rota (Sessão 1)

Entregável 1 do `prompts/prompt-01.md`: panorama das rotas client-side em R,
comparativo crítico e **recomendação** para o caso "dataviz interativa
publicada no GitHub Pages". A rota escolhida no fim deste documento **trava as
decisões da Sessão 2**.

**Data:** 2026-06-27 · **Ambiente:** ver `docs/00-ambiente.md` (R 4.6.0,
Quarto 1.9.37).
**Estado do WASM nesta data:** webR roda **R 4.6.0** compilado para
`wasm32-unknown-emscripten` (Emscripten 4.0.8).

> Nota de método: tudo abaixo foi conferido contra as fontes oficiais atuais
> (docs.r-wasm.org, r-wasm/quarto-live, posit-dev/r-shinylive) em jun/2026,
> porque compatibilidade WASM muda rápido e não é confiável de memória. Onde há
> incerteza viva (ex.: número exato de pacotes com binário), o texto aponta para
> a fonte ao vivo em vez de cravar um número que envelhece.

---

## 1. O que é cada rota

As três operam sobre o **mesmo motor**: R compilado para WebAssembly (webR).
A diferença está na *camada de cima* — como o código R é embutido, executado e
apresentado na página. Nenhuma delas precisa de servidor R: o navegador baixa o
runtime e roda tudo localmente.

### Shinylive (`{shinylive}`, posit-dev)
Shiny rodando **100% no navegador** via webR — sem Shiny Server, sem
`shinyapps.io`. O pacote `{shinylive}` exporta um `app.R`/`app.qmd` para um
diretório estático (`shinylive::export(appdir, destdir)`) que pode ser servido
em qualquer hosting estático. Você mantém o modelo mental do Shiny
(`ui`/`server`, `reactive()`, `observeEvent()`), mas o custo de computação migra
do servidor para a máquina do usuário.

### webR / Quarto Live (`r-wasm/quarto-live`) + OJS
Extensão Quarto que transforma blocos de código em **células interativas** dentro
de um documento HTML (`format: live-html`, `engine: knitr`). Troca-se `{r}` por
`{webr}` e o leitor pode editar e reexecutar o código na própria página. O ponto
forte é a **integração com OJS** (Observable JS): inputs OJS (`Inputs.select`,
`Inputs.range`, checkboxes) alimentam reativamente células `{webr}` via as opções
`#| input:` e `#| define:`. É reatividade leve, centrada em documento — ideal
para "texto + um gráfico que responde a um controle". Suporta saída
`htmlwidgets`/`htmltools`.

> OJS sozinho (sem webR) também roda no navegador, mas é **JavaScript**, não R.
> O valor do Quarto Live é justamente costurar OJS (controles/reatividade) com R
> real (sua análise) na mesma página.

### Quarto Dashboards (`format: dashboard`)
É uma **camada de layout**, não um motor de execução. Organiza saídas em
`cards`, linhas, colunas, abas e value boxes. Por padrão é **estático** (gráficos
renderizados no build). Vira interativo **só quando combinado** com uma das rotas
acima (células webR/OJS embutidas, ou um Shinylive incorporado). Sozinho, não dá
interatividade client-side — dá *apresentação*.

---

## 2. Elas não são mutuamente exclusivas

Este é o erro conceitual a evitar: tratá-las como três opções concorrentes. Na
prática se **compõem**:

- Um **Quarto Dashboard** pode embutir células **webR/OJS** → dashboard reativo
  sem servidor.
- Um **Shinylive** pode ser embutido dentro de um documento/slide Quarto (via a
  extensão `quarto-ext/shinylive`).
- **Quarto Live** já integra **OJS** por dentro.

O eixo de decisão real não é "qual das três", e sim **quanto de reatividade você
precisa** e **quanto peso está disposto a pagar por ela**:

```
estático ───────────────────────────────────────────► reativo pesado
Quarto (HTML)   Quarto Dashboard   Quarto Live (webR+OJS)   Shinylive
  (sem R no       (layout, ainda      (reatividade leve,      (modelo Shiny
   cliente)        estático)           doc-cêntrica)           completo)
```

---

## 3. Comparativo crítico

| Critério | Quarto Live (webR + OJS) | Shinylive | Quarto Dashboard |
|---|---|---|---|
| Paradigma | Documento com células reativas | App Shiny completo | Layout/apresentação |
| Reatividade | Leve (OJS ↔ webR) | Completa (`reactive`/`observe`) | Nenhuma sozinho |
| Peso inicial | webR base + pacotes pedidos | **~60 MB+** (base webR + todo `{shiny}` e deps) | ~0 se estático; herda da rota embutida |
| Cold start | Médio (init do webR) | **Alto** (init webR + carga do Shiny) | Baixo se estático |
| Curva | Baixa p/ quem usa Quarto | Baixa p/ quem já faz Shiny | Baixa |
| Melhor p/ | Viz embutida em narrativa/relatório | Apps com fluxo reativo rico | Painéis de indicadores |

### 3.1 Peso de carregamento (o "imposto WASM")
O navegador baixa o runtime na primeira visita. Ordem de grandeza:

- **Quarto Live:** base do webR + **apenas os pacotes que você declarar** em
  `webr.packages`. Um exemplo com `ggplot2`/`dplyr` fica na casa de alguns MB +
  base. Controlável.
- **Shinylive:** baseline citado pela própria comunidade é de **~60 MB ou mais**,
  porque carrega o webR base **e todas as dependências do `{shiny}`**, mesmo num
  app trivial. É o preço de admissão, não escala com a complexidade do seu app —
  mas é alto já no "olá mundo".

Implicação direta: quem paga a banda agora é o **usuário final**, não o host.
Para uma audiência de pesquisa (rede institucional, mobile), 60 MB no primeiro
load é um custo real de UX.

### 3.2 Latência de inicialização (cold start)
Há sempre um intervalo entre abrir a página e o runtime ficar pronto (o webR
exibe um banner "downloading, please wait..."). É inerente: o R precisa ser
baixado, instanciado e ter os pacotes montados no filesystem virtual antes de a
primeira linha rodar. Quarto Live mitiga porque você controla o conjunto de
pacotes; Shinylive sofre mais por causa do baseline.

### 3.3 Quais pacotes R **não** rodam em WASM (o ponto mais crítico)
Regra de ouro: **não se compila pacote da fonte no navegador.** O toolchain de
compilação (Emscripten/LLVM) não roda dentro do WASM. Só dá para **carregar
binários já compilados**, vindos de:

1. o **repositório binário público do webR** (CDN), e/ou
2. o **R-universe**, que compila binários WASM automaticamente, e/ou
3. binários próprios, gerados com o pacote **`{rwasm}`** (v0.3.0) + GitHub Actions
   (`r-wasm/actions`).

A **grande maioria** dos pacotes de CRAN já tem binário WASM disponível — a
contagem ao vivo está em **<https://repo.r-wasm.org/>** (dashboard do
repositório). Mas a cobertura **não é total**, e os furos seguem um padrão:

- **Dependem de biblioteca de sistema não portada.** O webR traz ~25 libs C/C++
  (inclui GDAL e deps → `sf`/`terra` existem, porém **pesados**; libs de
  gráficos). Pacote que exige uma lib fora dessa lista **não carrega** até alguém
  portar a lib.
- **Acessam recursos proibidos no WASM** (ver 3.4): rede por socket, shell,
  multiprocessos, filesystem do SO.
- **Código compilado exótico** (alguns pacotes com Fortran/Rust específicos) pode
  faltar ou ficar para trás de versão.

**Cilada de versão (recente, real):** ao subir o Emscripten para 4.0.8, binários
compilados para versões anteriores do webR **deixaram de ser compatíveis**
(r-wasm/webr #603). Se você fixar uma versão do webR e hospedar binários próprios,
um *version skew* entre o runtime e os binários quebra o carregamento. Para um
sandbox isso é gerenciável; para algo que você vai manter por anos nos projetos
de pesquisa, é um ponto de manutenção a vigiar.

### 3.4 O que costuma quebrar na prática
- **Rede.** WASM **não abre sockets** nem fala HTTP direto. `download.file()`,
  `curl`, `httr2` não funcionam "puros" — exigem o mecanismo de
  *WebSocket proxy + túnel SOCKS* fora do navegador (webR ≥ versões recentes).
  **Consequência para nós:** *não* baixar dado em runtime. O dado tem de viajar
  **junto** (CSV versionado no repo, ou exportado em build-time e injetado via
  OJS). Isso casa com o que o ROADMAP já pede na Sessão 2.
- **Leitura de arquivo local.** Não há filesystem do SO; só o *virtual filesystem*
  do webR. Arquivos precisam ser empacotados/montados (`webr::mount`) ou embutidos.
- **Locale e números no padrão BR.** O R do webR roda em locale "C". **Não confie**
  em `Sys.setlocale()` para formatar número. O caminho confiável é **explicitar as
  marcas**: `format(x, big.mark = ".", decimal.mark = ",")` ou
  `scales::label_number(big.mark = ".", decimal.mark = ",")` — são operações de
  string em nível de R, independem do locale do sistema, e funcionam. Datas/meses
  por extenso em português pelo locale também são frágeis; prefira mapear
  manualmente.
- **Fontes.** Renderização de gráfico depende das fontes embarcadas no runtime
  (suporte Cairo/Fontconfig está presente, mas o leque de fontes é limitado).
  Fonte custom da identidade do relatório pode simplesmente não aparecer. Para o
  exemplo mínimo, ficar nas fontes padrão.
- **Atrito de ambiente de build (Quarto Live):** há relatos de comportamento
  divergente entre **RStudio × VS Code/Positron** ao renderizar, e de Quarto Live
  **não funcionar bem dentro de projetos `book`**. Para a Sessão 2, renderizar
  pelo **Quarto CLI / RStudio** e como documento simples (não `book`) evita esse
  campo minado.

---

## 4. Recomendação

Para **"dataviz interativa publicada no GitHub Pages"**, embutível depois nos
projetos de pesquisa:

> **Rota primária: webR via Quarto Live (`format: live-html`), com OJS para os
> controles.**

Justificativa, em ordem de peso:

1. **Footprint controlável.** Carrega só os pacotes que você declarar — o oposto
   do baseline de ~60 MB do Shinylive. Crítico para audiência de pesquisa.
2. **Encaixe no fluxo de trabalho.** Seu output já é Quarto (RSP-style: prosa +
   análise + figura). Quarto Live adiciona **interatividade na figura sem trocar
   o paradigma** — é a costura natural com os projetos de pesquisa, que é o
   objetivo final do sandbox.
3. **Reatividade suficiente para o alvo.** "Um gráfico que responde a um
   controle" (filtro/seletor) é exatamente o ponto doce do OJS ↔ webR. Não exige
   a maquinaria do Shiny.
4. **Cold start menor** que Shinylive, pelos motivos de peso acima.

**Quando NÃO seguir essa rota — usar Shinylive:** se o que você precisa é
**reatividade estilo Shiny de verdade** (múltiplos outputs interdependentes,
`reactiveVal`, `observe`, validação de inputs encadeada, módulos), ou se você
**já tem um app Shiny** e o objetivo é só publicá-lo sem servidor. Aí o custo dos
~60 MB se paga.

**Quanto a Quarto Dashboards:** não é concorrente — é a **camada de layout** para
*depois*. Se um dia a entrega for um painel com vários cards, embute-se células
webR num `format: dashboard`. Fora de escopo para o primeiro entregável.

### Ressalva honesta
A recomendação vale para o alvo declarado (viz leve, doc-cêntrica). Ela **não** é
um veredito universal "Quarto Live > Shinylive": são ferramentas para problemas
de reatividade diferentes. O critério decisivo é **grau de reatividade × peso
aceitável**, não preferência estética.

---

## 5. Rota escolhida (trava a Sessão 2)

- **Rota:** **Quarto Live** (`format: live-html`, `engine: knitr`, blocos
  `{webr}` + controles `{ojs}`).
- **Restrições herdadas para a Sessão 2:**
  - Dado **viaja junto** (CSV pequeno em `data/`), **nunca** baixado em runtime.
  - Usar **apenas** pacotes com binário WASM confirmado no repo do webR
    (alvo do exemplo: `ggplot2` + `dplyr` — ambos presentes). Conferir em
    <https://repo.r-wasm.org/> antes de adicionar qualquer pacote.
  - Números BR via `decimal.mark`/`big.mark` **explícitos** (não via locale).
  - Escopo do exemplo: **um** gráfico reagindo a **um** controle. Nada além.
  - Renderizar com Quarto CLI/RStudio; documento simples (não `book`).
  - Convenções de código do `CLAUDE.md`: `|>`, `str_c()`, `theme_bw()`,
    comentários em inglês.

---

### Fontes consultadas (jun/2026)
- webR — docs e repositório binário: <https://docs.r-wasm.org/webr/latest/> ·
  <https://repo.r-wasm.org/>
- webR releases (Emscripten 4.0.8, incompatibilidade de binários #603):
  <https://github.com/r-wasm/webr/releases>
- `{rwasm}` v0.3.0 (build de binários WASM): <https://github.com/r-wasm/rwasm>
- Quarto Live (uso, OJS, pacotes): <https://r-wasm.github.io/quarto-live/>
- Shinylive R (export, baseline de peso): <https://github.com/posit-dev/r-shinylive>
- R-universe + WASM (build automático de binários):
  <https://ropensci.org/blog/2023/11/17/runiverse-wasm/>
