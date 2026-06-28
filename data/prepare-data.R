# Build-time data prep (NOT run in the browser).
# Source: IBGE SIDRA table 6579 — "Populacao residente estimada" by UF, per year.
# We fetch once here, tidy it, and commit a small CSV so the webR runtime never
# touches the network (sockets are blocked under WASM — see docs/01-panorama-rotas.md).

library(jsonlite)
library(dplyr)
library(readr)

url <- "https://apisidra.ibge.gov.br/values/t/6579/n3/all/v/all/p/2010-2021"

raw <- fromJSON(url)

# Row 1 is SIDRA's header description; drop it and keep the typed columns we need.
pop <- raw |>
  slice(-1) |>
  transmute(
    uf        = D1N,
    ano       = as.integer(D3N),
    populacao = as.integer(V)
  ) |>
  arrange(uf, ano)

write_csv(pop, "data/populacao-uf.csv")

cat("rows:", nrow(pop), "| ufs:", n_distinct(pop$uf),
    "| years:", min(pop$ano), "-", max(pop$ano), "\n")
