---
name: make
description: Use when writing or modifying Makefile targets.
version: 3.1.0
---

# br4zz4:make

> **TLDR**: o `Makefile` do projeto só faz `include .commons/make/main.mk` (e `.project/make/*.mk` para targets próprios). O commons gera os targets de todo módulo a partir do `.github/modules.json`: `make <módulo>.<step>` roda o mesmo hook `ci/checks/<step>.sh` do CI e `make <módulo>.<nome>` roda `code/run/<nome>`. Não há Makefile por módulo.

## Raiz

```makefile
include .commons/make/main.mk
include .project/make/*.mk
```

`commons.ctx` (raiz) declara projeto, ambientes, vault e escopo; nada disso mora no commons. `make help` lista tudo.

## Targets gerados

| make | roda |
|---|---|
| `<m>.lint` `<m>.audit` `<m>.test` `<m>.build` | `<code>/ci/checks/<step>.sh` |
| `<m>.validate` `<m>.plan` | `<infra>/ci/checks/<step>.sh` |
| `<m>.<nome>` | `<code>/run/<nome>` (um target por arquivo) |
| `<m>.shell` `<m>.db` `<m>.keys` | shell, `psql "$DATABASE_URL"`, nomes das chaves do escopo |
| `<m>.remote` `<m>.secrets` | `<infra>/ops/remote.sh`, Secret push via `<infra>/ops/secrets.sh` |
| `up` `down` `logs` | serviços do compose |
| `conform` `github.setup` `commons.update` | validação do projeto, config do GitHub, atualização do submodule |

- O nome do target é o nome do arquivo em `run/` sem prefixo: `run/db.seed` vira `make core.db.seed` (não existe `core.run.seed`).
- Argumentos: `ARGS="..."`. Ambiente: `ENV=` (default por tipo de comando, vindo do `commons.ctx`). Ambiente restrito pede `CONFIRM=<projeto>` fora de TTY.
- O ambiente vem do ward (`COMMONS_SCOPE`) e o toolchain do `mise.toml` do lado; o script roda com cwd no dir do lado e `MODULE`, `ENVIRONMENT`, `TAG`, `CI_CACHE_DIR`.

## Regras

- **O hook é a implementação.** `ci/checks/*.sh` tem a lógica; o make só o invoca. Nunca faça o hook chamar make.
- `run/<nome>` não pode ter nome reservado (`lint audit test build validate plan shell db keys remote secrets`): `make conform` reprova.
- `infra/ops/` só aceita `remote.sh` e `secrets.sh`.
- Target próprio do projeto vai em `.project/make/*.mk`, com prefixo `<módulo>.` (ex.: `core.account.status`), uma linha ou um script em `.project/scripts/` (1 script ↔ 1 target). Descrição com `## texto` aparece no `make help`.
- Lógica de mais de um comando nunca fica inline no Makefile.
- **Dependência de serviço não sobe pelo make** nem por wrapper shell ou função do commons: quem declara e sobe `database`, `mail` etc. é o `compose.yml` (`depends_on` com healthcheck), e o comando que precisa deles roda pelo compose (`br4zz4:docker`).
- `run/<nome>` que sobe processo (ex.: `run/start`) carrega o `.env` da raiz antes de chamar o Rails e exige as variáveis (`${WEB_PORT:?...}`): o `Dotenv` do Rails só carrega depois que o shell já expandiu os valores, e um default (`${PORT:-3000}`) esconde o erro.
- Nunca copie targets do commons para o projeto: ajuste o commons.
