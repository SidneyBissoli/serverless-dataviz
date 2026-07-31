# 02 — Lições e receita reaproveitável (Sessão 4)

Fechamento do `prompts/prompt-01.md`. As Sessões 0–3 produziram, validaram e
publicaram o entregável; esta sessão é **reflexão, sem código**. Registra o que
funcionou, o que quebrou de verdade, quais pacotes R caíram no WASM, o peso e a
latência reais, e — o que mais importa para o objetivo do sandbox — uma **receita
acionável** para embutir uma viz client-side em R nos projetos de pesquisa.

**Data:** 2026-06-28 · **Ambiente:** R 4.6.0, Quarto 1.9.37 (ver `docs/00-ambiente.md`).
**Leituras irmãs:** `docs/01-panorama-rotas.md` (decisão de rota e ciladas WASM),
`docs/03-handoff-sessao3.md` (plano de publicação), `docs/ROADMAP.md`.
**Estado:** o critério de sucesso da 1ª etapa do projeto **foi atingido** — a
página carrega e roda 100% no navegador, sem backend, em
<https://sidneybissoli.github.io/serverless-dataviz/>.

---

## 1. O que funcionou

A rota **Quarto Live** (`format: live-html`, `engine: knitr`) funcionou ponta a
ponta, do exemplo local à URL pública, **sem surpresa que invalidasse a escolha
da Sessão 1**. A espinha do exemplo:

- Uma célula `{webr}` de *setup* (`#| autorun: true`, `#| define: ufs`) carrega
  `dplyr`/`ggplot2` e lê o CSV **uma vez** quando o runtime fica pronto. O objeto
  `pop` **persiste na sessão webR** e é reusado pela célula do gráfico — carregar
  uma vez, reusar, sem reler dado a cada interação.
- Um controle `{ojs}` (`Inputs.select`) é a única peça reativa de UI; ele
  alimenta a célula do gráfico via `#| input: sel_uf`.
- A célula `{webr}` do gráfico recalcula a série temporal localmente a cada troca
  de UF.

A validação foi concreta, não "parece que carregou": trocar **São Paulo →
Tocantins** reescalou o eixo Y de ~42–46 milhões para ~1,4–1,6 milhão, com os
números no padrão brasileiro e **0 erros de console** depois que o runtime
terminou de carregar. O CSV resolveu corretamente sob o subpath
`/serverless-dataviz/` e o `.wasm` foi servido com o MIME certo (o R rodou).

A publicação por **GitHub Actions** (CI renderiza com `quarto render` e faz
deploy no Pages, com *source* = "GitHub Actions", não branch) também funcionou.
Essa estratégia foi escolhida deliberadamente sobre `quarto publish gh-pages`
justamente porque a **receita de CI é o ativo reaproveitável** para os projetos
de pesquisa — e é o foco da seção 5.

---

## 2. O que quebrou (e como foi contornado)

### A que de fato mordeu: `rmarkdown` ausente no CI

O plano da Sessão 3 dizia "instalar **apenas** `knitr`" no runner. A realidade
corrigiu: a **1ª run de CI falhou** com `there is no package called 'rmarkdown'`.
O motivo é estrutural — o `engine: knitr` do Quarto tece o documento para HTML
**via `rmarkdown`**, então o runner precisa de **`knitr` E `rmarkdown`**. Correção:
instalar os dois (`install.packages(c("knitr", "rmarkdown"))`).

A contrapartida vale registrar como aprendizado, porque é contraintuitiva: as
células `{webr}` **não são avaliadas no render** — elas rodam no navegador. Logo,
o CI **não precisa** de `dplyr`/`ggplot2`/`scales`; precisa só do ferramental de
render. Acertar essa fronteira é o que mantém o CI enxuto. A regra prática:
*o CI instala o que o knitr precisa para tecer a página; o navegador instala o
que a análise precisa para rodar.*

### As que não morderam porque foram respeitadas de antemão

Estas estavam mapeadas na Sessão 1 e o exemplo foi desenhado para não esbarrar
nelas. Não houve drama — e seria desonesto inflá-las como se tivessem quebrado:

- **Rede bloqueada no WASM.** Sem sockets; `download.file()`/`httr2` não servem.
  Contornado por construção: `data/prepare-data.R` busca a tabela SIDRA **em
  build-time**, salva um CSV pequeno, e o dado **viaja junto** com a página. Nada
  é baixado em runtime.
- **Locale "C".** Nada de `Sys.setlocale()` para número. Marcas **explícitas**
  via `scales::label_number(big.mark = ".", decimal.mark = ",")`. Funcionou.
- **Não se compila da fonte no navegador.** Ficamos em pacotes com binário WASM
  confirmado (ver seção 3).
- **Atrito de ambiente de build.** Documento simples (não projeto `book`),
  renderizado pelo Quarto CLI — evitou a divergência RStudio × VS Code/Positron.

### Riscos que continuam de pé (não morderam, mas vigiar)

- **Version skew do Emscripten 4.0.8 (#603).** Não nos afetou porque **não
  hospedamos binários próprios** — usamos o repositório do webR em runtime. Vira
  problema só se, no futuro, fixarmos uma versão do webR e servirmos binários
  gerados com `{rwasm}`. É ponto de manutenção para uso de **longo prazo** nos
  projetos de pesquisa, não para o sandbox.

### Cilada local (não-WASM) que custa um susto

No PowerShell do Windows, `R` é **alias de `Invoke-History`**. Para rodar R de
verdade, usar o caminho real (`& "C:\Program Files\R\R-4.6.0\bin\R.exe"` ou
`Rscript.exe`). Não tem nada a ver com WASM, mas reaparece em toda máquina nova.

---

## 3. Pacotes R no WASM

**Rodaram, sem erro de carga ou render:** `dplyr`, `ggplot2`, `scales` — os três
têm binário no repositório do webR (`repo.r-wasm.org`) e são declarados em
`webr.packages` no cabeçalho do `index.qmd`.

Decisões de footprint que pagaram:

- **I/O com `read.csv()` de base**, não `readr` — evita puxar `readr` para o WASM.
- **`str_c()` evitado de propósito.** A convenção do projeto pede `str_c()`, mas
  aqui não há concatenação de strings no código, e usá-lo só para cumprir a
  convenção arrastaria `stringr` para o navegador sem necessidade. Decisão
  consciente, registrada — não esquecimento.

**Regra de ouro:** no navegador **só carregam binários WASM já compilados** — o
toolchain de compilação não roda lá. Antes de adicionar **qualquer** pacote:

1. conferir a cobertura em **<https://repo.r-wasm.org/>** (repositório do webR); ou
2. checar o **R-universe** (compila binários WASM automaticamente); ou
3. gerar o binário com **`{rwasm}`** + `r-wasm/actions`.

Pacote que exige biblioteca de sistema **não portada** simplesmente não carrega.
E, repetindo o ponto da seção 2: esses pacotes de análise **não vão para o CI** —
o runner só precisa de `knitr`/`rmarkdown`.

---

## 4. Peso e latência reais

Números observados (e o que cada ferramenta conseguiu ou não medir):

| Métrica | Observado | Como foi medido |
|---|---|---|
| Cold start (cache frio), ponta a ponta | **~25–30 s** (≈20–30 s na URL pública) | cronômetro: download do webR + instalação dos pacotes + 1ª render |
| Interação morna (trocar UF) | **~1–2 s** | recálculo client-side, runtime já quente |
| *Shell* da página (main thread) | **~2,2 MB** | painel de rede do navegador |
| Runtime webR + binários | **não medido** | baixado **dentro do Web Worker**; o painel de rede do navegador **não capturou** |

A ressalva honesta importa: **não temos um total de banda medido.** O painel de
rede vê os ~2,2 MB do shell na main thread, mas o webR e os binários descem
dentro do Web Worker e ficaram fora do alcance da ferramenta. Cravar um "total em
MB" aqui seria chute. O que dá para afirmar com segurança é (a) a página carrega
**apenas os 3 pacotes declarados** mais a base do webR, e (b) o shell mensurável
é ~2,2 MB.

**Comparação com Shinylive — honesta sobre o que é medido vs. citado.** O baseline
do Shinylive é **~60 MB já no "olá mundo"**, porque carrega a base do webR **e
todas as dependências do `{shiny}`** mesmo num app trivial. Esse número é o
baseline documentado da rota Shinylive, **não algo que remedimos aqui**. A
vantagem estrutural do Quarto Live permanece — carregar só o que se declara, não
o `{shiny}` inteiro —, mas a comparação correta é "3 pacotes declarados + base"
versus "base + `{shiny}` completo", e não dois totais medidos lado a lado.

**Leitura prática:** o custo real de UX desta rota é o **cold start de ~25–30 s**,
mais do que o tamanho do download em si. Para audiência de pesquisa em rede
institucional ou mobile, o que pesa é o primeiro carregamento de alguns segundos.
Depois de quente, a interação é fluida (~1–2 s).

---

## 5. Receita reaproveitável

**Esta é a razão de existir do sandbox.** Checklist para embutir uma viz
client-side em R num projeto de pesquisa. Tudo abaixo está calcado nos arquivos
reais deste repositório — copie e adapte.

### 5.1 Estrutura de arquivos

```
projeto/
├─ _quarto.yml
├─ .gitignore
├─ .nojekyll
├─ index.qmd                      # documento live-html (a viz)
├─ data/
│  ├─ prepare-data.R              # fetch/tidy em BUILD-TIME (NÃO roda no navegador)
│  └─ <dado>.csv                  # pequeno, versionado, viaja com a página
├─ _extensions/r-wasm/live/       # extensão Quarto Live — VERSIONAR (o CI precisa dela)
└─ .github/workflows/publish.yml  # render + deploy no Pages
```

> A extensão Quarto Live é adicionada com `quarto add r-wasm/quarto-live`
> (confirme o slug atual na página do projeto) e **deve ser commitada** — o CI
> renderiza com ela, não a reinstala.

### 5.2 `index.qmd` — cabeçalho e padrão reativo

Cabeçalho mínimo (declare aqui **só** os pacotes que rodam no navegador):

```yaml
---
title: "..."
lang: pt
format:
  live-html:
    webr:
      packages: [dplyr, ggplot2, scales]   # binários WASM confirmados
engine: knitr
resources:
  - data            # embarca a pasta data/ no site → vira legível no VFS do webR
---

{{< include _extensions/r-wasm/live/_knitr.qmd >}}
```

O padrão reativo é **três células** — é o coração da receita:

````markdown
```{webr}
#| autorun: true
#| echo: false
#| output: false
#| define:
#|   - choices            # objeto exportado para o OJS
library(dplyr); library(ggplot2)
# Data ships with the page — read from the WASM virtual filesystem, not the net.
df <- read.csv("data/<dado>.csv", fileEncoding = "UTF-8")
choices <- sort(unique(df$<col>))
```

```{ojs}
//| echo: false
viewof sel = Inputs.select(choices, { label: "...", value: "..." })
```

```{webr}
#| echo: false
#| input:
#|   - sel               # recebe o valor do controle OJS
# Brazilian number format set EXPLICITLY — never via locale (webR roda em "C").
br_number <- scales::label_number(big.mark = ".", decimal.mark = ",", accuracy = 1)
df |>
  filter(<col> == sel) |>
  ggplot(aes(x = ..., y = ...)) +
  geom_line() +
  scale_y_continuous(labels = br_number) +
  theme_bw()
```
````

Pontos que carregam a lógica: `#| define:` exporta um objeto da célula webR para
o OJS; `#| input:` injeta o valor do controle numa célula webR; `#| autorun: true`
faz o setup rodar assim que o runtime sobe. Convenções do `CLAUDE.md` aplicadas:
pipe `|>`, `theme_bw()`, comentários em inglês, números BR explícitos.

### 5.3 `_quarto.yml`

```yaml
project:
  type: website
  output-dir: _site
  render:
    - index.qmd        # publica só o entregável; docs/ e prompts/ ficam fora do site
  resources:
    - .nojekyll         # garante o marcador no output publicado
```

### 5.4 `.gitignore` e `.nojekyll`

Não versionar artefatos de build (o CI os gera):

```
/_site/
/.quarto/
/index_files/
index.html
```

`.nojekyll` (arquivo vazio na raiz) impede o Pages de rodar Jekyll, que mangueia
pastas iniciadas por `_` (`_extensions`, `index_files`). O deploy por artefato do
Actions já não roda Jekyll — mantido como cinto-e-suspensório.

### 5.5 CI — `.github/workflows/publish.yml`

O esqueleto que funcionou, **com a lição do `rmarkdown` embutida**:

```yaml
permissions:
  contents: read
  pages: write
  id-token: write          # OIDC para o deploy do Pages

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: quarto-dev/quarto-actions/setup@v2
      - uses: r-lib/actions/setup-r@v2
        with:
          use-public-rspm: true     # binários pré-compilados no runner (Linux), sem compilar da fonte
      - name: Install render-time R packages
        run: install.packages(c("knitr", "rmarkdown"))   # engine knitr tece via rmarkdown
        shell: Rscript {0}
      - run: quarto render --output-dir _site
      - uses: actions/upload-pages-artifact@v3
        with:
          path: _site
  deploy:
    needs: build
    runs-on: ubuntu-latest
    environment:
      name: github-pages
    steps:
      - uses: actions/deploy-pages@v4
```

> **Não cravar as tags `@vN` de memória.** As versões das actions migram;
> confirme os *majors* correntes de `quarto-actions`, `setup-r`,
> `upload-pages-artifact` e `deploy-pages` antes de reusar. Esse "conferir antes"
> é, em si, parte da receita.

### 5.6 Habilitar o Pages com *source* = GitHub Actions

```
gh api -X POST repos/{owner}/{repo}/pages -f build_type=workflow
```

(ou Settings → Pages → Source: **GitHub Actions**). **Não** é deploy por branch.

### 5.7 Checklist mental (as regras transversais)

- [ ] Dado **viaja com o repo** (CSV pequeno em `data/`); **nada** baixado em runtime.
- [ ] `prepare-data.R` faz o fetch em **build-time**, fora do navegador.
- [ ] **Só** pacotes com binário WASM confirmado em `repo.r-wasm.org`.
- [ ] Números BR via `big.mark`/`decimal.mark` **explícitos**, nunca por locale.
- [ ] Documento **simples** (não `book`); render pelo Quarto CLI.
- [ ] CI instala **`knitr` + `rmarkdown`** (não os pacotes de análise).
- [ ] `_extensions/r-wasm/live/` **commitada**.
- [ ] Pages com *source* = **GitHub Actions**.
- [ ] Conferir que assets e dado resolvem sob o **subpath** `/{repo}/` (a causa
      nº 1 de asset quebrado em Project Pages).

---

## 6. Próximos experimentos

O primeiro objetivo do sandbox **está cumprido** — a receita da seção 5 já basta
para embutir uma figura reativa leve num projeto de pesquisa. A lista abaixo é
curta de propósito: são sondas que **de fato** avançam o objetivo de embutir essa
capacidade na pesquisa em saúde, não preenchimento de escopo. Cada uma carrega a
pergunta que responde.

1. **`format: dashboard` com células webR.** O Quarto Dashboard é a *camada de
   layout* natural para painéis de indicadores — formato provável das entregas
   reais (ICSAP, cobertura de ESF). *Pergunta:* o padrão reativo webR ↔ OJS da
   seção 5.2 sobrevive limpo dentro de um layout de `cards`/`value boxes`?

2. **`sf` no WASM para um coroplético municipal.** Mapas municipais são saída
   central da minha pesquisa. O webR traz GDAL, então `sf` existe — mas é
   **pesado**. *Pergunta:* o cold start continua aceitável com `sf` + uma
   geometria municipal carregados? É a medição que falta para decidir se mapa
   interativo client-side é viável ou se mapa estático em build-time é o caminho.

3. **Dado acima de poucos KB.** O CSV-no-repo (aqui, ~8 KB) tem **teto**;
   extrações reais do DATASUS são ordens de magnitude maiores. *Pergunta:* qual o
   limite prático de tamanho antes de o cold start degradar a UX? Avaliar
   `webr::mount` de uma imagem de filesystem, ou pré-agregar/particionar o dado,
   **antes** de embutir algo data-intensivo.

Se um projeto específico só precisar de uma figura reativa leve, nenhum desses
experimentos é pré-requisito — a receita da seção 5 já entrega.

---

### Ponteiros para os arquivos reais
- Documento: `index.qmd` · Config: `_quarto.yml` · CI: `.github/workflows/publish.yml`
- Dado e prep: `data/populacao-uf.csv`, `data/prepare-data.R`
- Decisão de rota e ciladas: `docs/01-panorama-rotas.md` · Plano de publicação:
  `docs/03-handoff-sessao3.md` · Roadmap: `docs/ROADMAP.md`
- URL pública: <https://sidneybissoli.github.io/serverless-dataviz/>
