# ROADMAP — serverless-dataviz

Roadmap de implementação do que `prompts/prompt-01.md` pede, organizado **por
sessão de Claude**. Cada sessão indica a **plataforma Claude recomendada**
(nuvem / aplicativo [chat · cowork · code] / terminal) e por quê.

O prompt-01 tem três entregáveis, nesta ordem:

1. Panorama + comparativo crítico das rotas client-side em R, com recomendação.
2. Exemplo mínimo ponta a ponta (arquivos criados de fato).
3. Passo de publicação (build + deploy no GitHub Pages) com todos os configs.

A postura do projeto vale para todo o roadmap: **um primeiro entregável
completo e funcional > cobertura exaustiva. Não inflar escopo.**

---

## Mapa de plataformas (resumo)

| Sessão | Foco | Plataforma Claude | Por quê |
|--------|------|:-----------------:|---------|
| 0 | Verificar ambiente local | Terminal (Claude Code) | precisa rodar `R`, `quarto`, `git` na máquina |
| 1 | Panorama + decisão de rota (entregável 1) | App **Chat** (ou Nuvem) | tarefa conceitual; sem filesystem/execução |
| 2 | Exemplo mínimo ponta a ponta (entregável 2) | Terminal / App **Code** | cria arquivos, instala pacotes, faz build local |
| 3 | Publicação no GitHub Pages (entregável 3) | Terminal / App **Code** | `git`, `gh`, workflow do Actions, deploy |
| 4 | Fechamento e captura de aprendizado | App **Chat** | reflexão, sem código |

> Convenção: onde houver código R, seguir CLAUDE.md — pipe `|>`, `str_c()`,
> `theme_bw()`, comentários em inglês, números no padrão brasileiro nos outputs.

---

## Sessão 0 — Conferência de ambiente (pré-requisito)

**Plataforma:** Terminal (Claude Code) — única que executa binários locais.
**Objetivo:** garantir que a Sessão 2 não trave por falta de ferramenta.
*Pode ser fundida ao início da Sessão 2 se você já tiver tudo instalado.*

- [x] Confirmar versão do R (`R --version`) — idealmente ≥ 4.2 (pipe nativo `|>`). → R 4.6.0
- [x] Confirmar Quarto (`quarto --version`) — ≥ 1.4 para suporte maduro a webR/Live. → Quarto 1.9.37
- [x] Confirmar `git` e `gh` (`git --version`, `gh --version`) instalados e logados. → git 2.53.0, gh 2.86.0 (logado como SidneyBissoli)
- [x] Confirmar conta no GitHub e repositório remoto disponível (criar depois, na Sessão 3). → conta OK; repo remoto fica para a Sessão 3
- [x] Anotar versões num `docs/00-ambiente.md` (snapshot reprodutível). → criado

---

## Sessão 1 — Panorama e decisão de rota (entregável 1)

**Plataforma recomendada:** Aplicativo **Chat** (claude.ai ou app desktop).  
**Alternativa:** **Nuvem** — se quiser que o Claude verifique na web a
compatibilidade *atual* de pacotes R com WASM antes de recomendar.  
**Por que não terminal/Code aqui:** é síntese conceitual, não precisa de
filesystem nem de executar nada. O Code só agrega valor no fim, para gravar o
arquivo — o que pode ser feito colando o texto.  

**Entregável:** `docs/01-panorama-rotas.md`.  

- [x] Descrever, sem jargão solto, **o que cada rota é**:
  - [x] **Shinylive** — Shiny rodando 100% no navegador via WASM (sem servidor Shiny).
  - [x] **webR / Quarto Live (e OJS)** — R compilado p/ WASM dentro de documentos Quarto; células reativas leves.
  - [x] **Quarto Dashboards** — layout de dashboard; pode ser *estático* ou combinar-se com webR/Shinylive para interatividade.
- [x] Deixar explícito que **não são mutuamente exclusivas** (ex.: um Quarto
      Dashboard pode embutir células webR; Shinylive pode ser embutido em Quarto).
- [x] Comparativo crítico com **prós, contras e limitações reais**:
  - [x] Peso de carregamento WASM (MB baixados no primeiro acesso).
  - [x] Latência de inicialização (cold start do runtime no navegador).
  - [x] **Quais pacotes R não rodam em WASM** (o ponto mais crítico — ex.: pacotes com código compilado/system deps fora do repositório do webR).
  - [x] O que costuma quebrar na prática (fontes, locale/números BR, leitura de arquivos, dependências de rede).
- [x] Encerrar com **uma recomendação fundamentada** para o caso
      "dataviz interativa publicada no GitHub Pages" (provável: webR/Quarto Live
      para viz reativa leve; Shinylive só se precisar de reatividade estilo Shiny).
- [x] Registrar a rota escolhida — ela **trava as decisões da Sessão 2**. → **Quarto Live (webR + OJS)**; ver `docs/01-panorama-rotas.md`.

---

## Sessão 2 — Exemplo mínimo ponta a ponta (entregável 2)

**Plataforma recomendada:** **Terminal (Claude Code)** ou App **Code**.  
**Por quê:** cria arquivos de fato, instala pacotes, e roda `quarto render`
localmente para validar antes de publicar. Exige filesystem + execução.  

**Pré-requisito:** rota definida na Sessão 1.  

### 2a. Dados
- [x] Escolher **dataset pequeno e público** do domínio do usuário
      (ex.: série temporal DATASUS ou indicador municipal simples).
      → IBGE/SIDRA tabela 6579, **população estimada por UF, 2011–2021** (dado real, público).
- [x] Se optar por dataset **embutido** (ex.: de pacote), **justificar** a troca
      por motivo didático, conforme pede o prompt. → N/A: usado dado externo real, não embutido.
- [x] Salvar o dado versionado e leve em `data/` (CSV pequeno), não baixar em runtime
      se isso adicionar latência/falha de rede no navegador.
      → `data/populacao-uf.csv` (297 linhas, 8 KB); fetch só em **build-time** (`data/prepare-data.R`).

### 2b. Documento interativo
- [x] Criar o `.qmd` (ou app Shinylive) com a viz interativa mínima — **um**
      gráfico que responde a **um** controle (filtro/seletor). Não mais que isso.
      → `index.qmd` (`format: live-html`): 1 `Inputs.select` (UF) → 1 série temporal.
- [x] Aplicar convenções: `|>`, `str_c()`, `theme_bw()`, comentários em inglês,
      números no padrão brasileiro (vírgula decimal) no output.
      → `|>`, `theme_bw()`, comentários em inglês OK; números BR via `scales::label_number(big.mark=".", decimal.mark=",")` **explícito** (não locale). `str_c()` não usado: evitado de propósito para não puxar `stringr` p/ o WASM (sem concatenação de strings no código).
- [x] Confirmar que **todos os pacotes usados rodam em WASM** (cruzar com a
      lista de ciladas da Sessão 1 — falhar aqui é o erro mais comum).
      → `dplyr`, `ggplot2`, `scales` — todos com binário no repo do webR. Carregaram e renderizaram sem erro.

### 2c. Build local
- [x] `quarto render` local sem erro. → `index.html` gerado.
- [x] Abrir o HTML no navegador e confirmar: carrega, runtime inicializa, o
      controle funciona **inteiramente client-side** (este é o critério de
      sucesso da etapa 1 do projeto).
      → **Validado no Chrome** (servido em `http://127.0.0.1:8765`): webR inicializou, gráfico renderizou, troca de UF (São Paulo → Rio de Janeiro) **recalculou o gráfico client-side**, eixo y reescalou, **0 erros no console**. ✅ Critério de sucesso da etapa 1 atingido localmente.
- [x] Anotar peso final e tempo de cold start observados (sanidade vs. Sessão 1).
      → Cold start (cache frio): ~25–30 s ponta a ponta (download do webR + instalação dos pacotes + 1ª render). Interação morna (trocar UF): ~1–2 s. Shell de página (main thread): ~2,2 MB. **Peso do runtime webR + binários** é baixado dentro do **Web Worker** e não foi capturado pelas ferramentas de rede do navegador aqui — ordem de grandeza esperada: base do webR + os 3 pacotes declarados (poucos MB + base), coerente com a Sessão 1. Confirma a vantagem de footprint da rota Quarto Live vs. o baseline ~60 MB do Shinylive.

---

## Sessão 3 — Publicação no GitHub Pages (entregável 3)

**Plataforma recomendada:** **Terminal (Claude Code)** ou App **Code**.
**Por quê:** `git`, `gh`, criação dos arquivos de config e do workflow do
GitHub Actions, e o deploy em si.

**Pré-requisito:** exemplo renderizando localmente (Sessão 2).

- [x] Inicializar repo git (`git init`) e primeiro commit, se ainda não houver.
      → `git init -b main`; commit em PT. `_site/`, `.quarto/`, artefatos da raiz ignorados.
- [x] Criar repositório remoto no GitHub (`gh repo create`) e fazer push.
      → **público** `SidneyBissoli/serverless-dataviz` (nome confirmado com o usuário).
- [x] Definir estratégia de publicação e **especificar todos os configs**:
  - [x] `_quarto.yml` com `output-dir` coerente (ex.: `docs/` ou `_site/`).
        → `type: website`, `output-dir: _site`, `render: [index.qmd]` (docs/ e prompts/ ficam fora do site), `resources: [.nojekyll]`.
  - [x] `.github/workflows/*.yml` — render do Quarto + deploy no Pages.
        → **GitHub Actions** (estratégia travada): build (checkout → quarto setup@v2 → setup-r@v2 → instala knitr **e rmarkdown** → `quarto render`) → deploy (upload-pages-artifact@v3 → deploy-pages@v4).
  - [x] `.gitignore` (evitar versionar artefatos de build indesejados).
  - [x] `.nojekyll` se a saída tiver pastas iniciadas por `_` (evita o Jekyll quebrar assets).
        → na raiz e empacotado no `_site/` via `resources`. (Obs.: o deploy por artefato do Actions já não roda Jekyll; mantido como cinto-e-suspensório.)
- [x] Habilitar GitHub Pages no repositório (branch/pasta corretos).
      → source = **GitHub Actions** (`gh api pages -f build_type=workflow`), não branch.
- [x] Deploy e **validar a URL pública**: a página carrega e roda inteiramente
      no navegador, sem backend. ✅ Critério de sucesso da primeira etapa.
      → <https://sidneybissoli.github.io/serverless-dataviz/> validado no Chrome: webR cold-start (~20–30 s), gráfico de São Paulo renderizou; **trocar a UF para Tocantins recalculou o gráfico client-side** (y reescalou de ~42–46 mi para ~1,4–1,6 mi), números no padrão BR. **0 erros de console** após o runtime carregar (os `ufs is not defined` são transitórios do cold-start e somem).
- [x] Conferir armadilhas de Pages: caminhos relativos de assets, MIME do `.wasm`,
      tamanho/timeout do primeiro load.
      → Sem 404; `.wasm` servido OK (R rodou); `data/populacao-uf.csv` resolveu no subpath `/serverless-dataviz/` (gráfico tem dado real). 1ª run de CI exigiu 1 ajuste (faltava `rmarkdown` p/ o engine knitr) — corrigido, conforme previsto no handoff.

---

## Sessão 4 — Fechamento e captura de aprendizado

**Plataforma recomendada:** Aplicativo **Chat** — reflexão, sem código.

- [ ] Escrever `docs/02-licoes.md`: o que funcionou, o que quebrou, quais pacotes
      R caíram no WASM, peso/latência reais.
- [ ] Registrar a **receita reaproveitável** para embutir essa capacidade nos
      projetos de pesquisa em R (o objetivo final do sandbox).
- [ ] Listar próximos experimentos *somente se* agregarem (não inflar escopo).

---

## Critério de pronto (Definition of Done) do prompt-01

- [x] Entregável 1 escrito, com recomendação clara de rota. → `docs/01-panorama-rotas.md`
- [x] Entregável 2 existindo como arquivos reais e renderizando localmente. → `index.qmd` + `data/`.
- [x] Entregável 3 publicado: URL do GitHub Pages carrega e roda 100% no navegador.
      → <https://sidneybissoli.github.io/serverless-dataviz/> (deploy por GitHub Actions).
- [x] Ciladas de WASM documentadas **antes** de virarem bloqueio. → `docs/01-panorama-rotas.md` seç. 3.3/3.4.
