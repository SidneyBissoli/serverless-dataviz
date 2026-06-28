# 00 — Conferência de ambiente (Sessão 0)

Snapshot reprodutível das ferramentas locais necessárias para as Sessões 2 e 3.

**Data do snapshot:** 2026-06-27
**Máquina:** Windows 11 Pro (10.0.26200) · shell padrão: PowerShell 7+

## Versões verificadas

| Ferramenta | Versão instalada | Mínimo exigido (ROADMAP) | Status |
|------------|------------------|--------------------------|:------:|
| R          | 4.6.0 (2026-04-24, ucrt) | ≥ 4.2 (pipe nativo `\|>`) | ✅ |
| Quarto     | 1.9.37           | ≥ 1.4 (webR/Live maduro) | ✅ |
| git        | 2.53.0.windows.2 | qualquer recente          | ✅ |
| gh (GitHub CLI) | 2.86.0      | qualquer recente          | ✅ |

## Conta e autenticação

- **GitHub CLI:** logado em `github.com` como **SidneyBissoli** (keyring, token ativo).
- **Protocolo de operações git:** HTTPS.
- **git config global:** `user.name = SidneyBissoli`, `user.email = sbissoli76@gmail.com`.
- **Repositório remoto:** ainda não criado — será feito na **Sessão 3**
  (`gh repo create` + push). A conta já está pronta para isso.

## Estado do diretório do projeto

- `serverless-dataviz/` **ainda não é um repositório git** (`git init` fica para
  a Sessão 3, conforme o ROADMAP).

## Ciladas observadas nesta máquina

- **`R` é um alias do PowerShell** para `Invoke-History`. Chamar `R --version`
  no PowerShell falha ("Cannot locate the history..."). Nas próximas sessões,
  invocar o binário real:
  - `& "C:\Program Files\R\R-4.6.0\bin\R.exe" --version`, ou
  - usar `Rscript.exe` (em `C:\Program Files\R\R-4.6.0\bin\`), que não colide.
  - O Quarto chama o R pelo caminho instalado, então o render não é afetado;
    o problema é só ao rodar `R` manualmente no PowerShell.

## Conclusão

Ambiente **pronto** para a Sessão 2 (exemplo mínimo ponta a ponta) e a Sessão 3
(publicação). Nenhuma ferramenta faltando; todas as versões acima do mínimo.
