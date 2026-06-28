# Handoff — Sessão 3 (Publicação no GitHub Pages)

> Documento de passagem de bastão. Se você é uma sessão Claude com contexto
> limpo e o usuário pediu **"implementar a sessão 3"**, **leia este arquivo
> inteiro primeiro**, depois `docs/ROADMAP.md` (Sessão 3) e `docs/01-panorama-rotas.md`
> (seção 3.4, ciladas WASM). Só então comece a agir.

## Estado atual (fim da Sessão 2)

- Sessões 0, 1 e 2 **concluídas e validadas** (ver checkboxes no ROADMAP).
- Rota travada: **Quarto Live** (`format: live-html`, `engine: knitr`, `{webr}` + `{ojs}`).
- Entregável 2 funciona: `index.qmd` renderiza e foi **validado em navegador**
  (webR inicializa, gráfico recalcula client-side ao trocar a UF, 0 erros de console).
- **Ainda NÃO é repo git** e **não há remoto no GitHub** — isso é tarefa da Sessão 3.
- GitHub CLI logado como **SidneyBissoli** (HTTPS); `git config` global já definido
  (Sidney Bissoli / sbissoli76@gmail.com). Ver `docs/00-ambiente.md`.

## Decisão travada com o usuário

**Estratégia de publicação: GitHub Actions (CI renderiza + faz deploy no Pages).**
É o item primário do ROADMAP. Justificativa do usuário: quer a receita de CI
reaproveitável para os projetos de pesquisa. (Alternativas descartadas:
`quarto publish gh-pages` e commit do site no repo.)

## Arquivos da Sessão 2 já presentes

- `index.qmd` (raiz) — documento Quarto Live.
- `data/populacao-uf.csv` + `data/prepare-data.R` — dado versionado (8 KB) + prep build-time.
- `_extensions/r-wasm/live/` — extensão Quarto Live (versionar; o CI precisa dela).
- **Artefatos de build na raiz que devem ser limpos/ignorados:** `index.html`,
  `index_files/`, e a pasta oculta `.quarto/` se aparecer.

---

## Plano determinístico da Sessão 3

### Passo 0 — Pré-flight
- Confirmar que está em `C:\Users\SIDNEY\OneDrive\programacao\serverless-dataviz`.
- **Cilada de ambiente:** no PowerShell, `R` é alias de `Invoke-History`. Para
  rodar R use o caminho real: `& "C:\Program Files\R\R-4.6.0\bin\R.exe"` ou `Rscript.exe`.

### Passo 1 — Configs do projeto (criar de fato)
1. **`_quarto.yml`** mínimo, tipo website, com saída isolada:
   ```yaml
   project:
     type: website
     output-dir: _site
   ```
   (Isolar em `_site/` **de propósito**: a pasta `docs/` já guarda as notas
   `.md` do projeto; jogar o site lá colidiria.)
2. **`.gitignore`** — não versionar artefatos de build:
   ```
   /_site/
   /.quarto/
   /index_files/
   index.html
   ```
   E **remover** os artefatos da raiz já existentes antes do primeiro commit
   (`index.html`, `index_files/`).
3. **`.nojekyll`** (arquivo vazio na raiz) — Pages não deve rodar Jekyll, que
   mangueia pastas/arquivos iniciados por `_` (quebra assets). Garantir também
   que ele chegue no `_site/` publicado (o deploy do artefato serve o conteúdo
   de `_site` como está).

### Passo 2 — Workflow de CI (`.github/workflows/publish.yml`)
> **IMPORTANTE — não cravar YAML de memória.** As versões das actions mudam.
> ANTES de escrever, buscar a doc atual de `quarto-dev/quarto-actions`
> (via Context7 ou WebFetch em <https://github.com/quarto-dev/quarto-actions>)
> e do deploy de Pages (`actions/deploy-pages`). Conferir as tags `@vN` correntes.

Forma esperada (validar versões antes de usar):
- Gatilho: `push` na branch `main`.
- Permissões: `contents: read`, `pages: write`, `id-token: write`.
- Job **build**: `actions/checkout` → `quarto-dev/quarto-actions/setup` →
  `r-lib/actions/setup-r` → instalar **apenas `knitr`** (os blocos `{webr}` NÃO
  rodam no render; rodam no navegador — não instalar dplyr/ggplot2/scales no CI)
  → `quarto render` → `actions/upload-pages-artifact` com `path: _site`.
- Job **deploy**: `needs: build`, `environment: github-pages`,
  `actions/deploy-pages`.
- **Hedge honesto:** se o `quarto render` no CI falhar pedindo um pacote, é
  porque algum bloco está sendo avaliado pelo knitr — aí adicionar o pacote
  faltante ao setup-r-dependencies. Não presumir; ler o log.

### Passo 3 — Repositório e push
- `git init` + primeiro commit (mensagem em PT, terminar com a linha
  `Co-Authored-By: Claude ...` conforme convenção do harness).
- `gh repo create serverless-dataviz --public --source . --push` (confirmar o
  nome com o usuário; público é necessário para Pages no plano free).

### Passo 4 — Habilitar Pages
- Definir a **source do Pages como "GitHub Actions"** (não "branch"):
  `gh api -X POST repos/{owner}/serverless-dataviz/pages -f build_type=workflow`
  (ou orientar o usuário a fazê-lo na UI, se a API exigir confirmação).
- Disparar/observar o workflow: `gh run watch` / `gh run list`.

### Passo 5 — Validar a URL pública (critério de sucesso da etapa 1)
- Abrir `https://sidneybissoli.github.io/serverless-dataviz/` no navegador
  (usar as ferramentas claude-in-chrome, como na Sessão 2).
- Confirmar, de fato: página carrega → banner do webR → **trocar a UF recalcula
  o gráfico client-side** → 0 erros no console. Só então declarar sucesso.

### Passo 6 — Conferir ciladas de Pages
- **MIME do `.wasm`:** o Pages serve `.wasm` como `application/wasm` (ok hoje);
  se o webR reclamar, investigar.
- **Caminhos relativos:** o site fica em subpath `/serverless-dataviz/`. Conferir
  se `data/populacao-uf.csv` e os assets do `index_files/libs` resolvem no subpath.
  Se quebrar, é o ponto nº 1 a investigar (path absoluto vs relativo).
- **Primeiro load:** anotar tempo real de cold start na URL pública vs. local.

## Riscos residuais (não elimináveis de antemão — ser honesto no relato)
- Propagação do Pages após o 1º deploy pode levar alguns minutos (404 temporário).
- Primeira execução de CI costuma exigir 1–2 ajustes de versão de action.
- Subpath `/serverless-dataviz/` é a causa mais provável de asset quebrado.

## Definition of Done da Sessão 3
- URL pública do GitHub Pages carrega e **roda 100% no navegador, sem backend**.
- Trocar o controle recalcula o gráfico client-side na URL pública.
- Configs todos versionados; `main` sem artefatos de build.
- Marcar os checkboxes da Sessão 3 no `docs/ROADMAP.md` com anotações.
