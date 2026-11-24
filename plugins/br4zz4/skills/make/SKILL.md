---
name: make
description: Use when writing or modifying Makefile targets.
version: 3.3.0
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
| `<m>.lint` `<m>.audit` `<m>.test` | `<code>/run/<step>` no container do módulo (cai em `ci/checks/<step>.sh` se não existir) |
| `<m>.build` | `<code>/ci/checks/build.sh` |
| `<m>.validate` `<m>.plan` | `<infra>/ci/checks/<step>.sh` |
| `<m>.<nome>` | `<code>/run/<nome>` (um target por arquivo) |
| `<m>.shell` `<m>.db` `<m>.keys` | shell, `psql "$DATABASE_URL"`, nomes das chaves do escopo |
| `<m>.remote` `<m>.secrets` | `<infra>/ops/remote.sh`, Secret push via `<infra>/ops/secrets.sh` |
| `up` `down` `logs` | serviços do compose |
| `conform` `git.origin.setup` `commons.update` | validação do projeto, config do GitHub, atualização do submodule |

- O nome do target é o nome do arquivo em `run/` sem prefixo: `run/db.seed` vira `make core.db.seed` (não existe `core.run.seed`).
- Argumentos: `ARGS="..."`. Ambiente: `ENV=` (default por tipo de comando, vindo do `commons.ctx`). Ambiente restrito pede `CONFIRM=<projeto>` fora de TTY.
- O ambiente vem do ward (`COMMONS_SCOPE`) e o toolchain do `mise.toml` do lado; o script roda com cwd no dir do lado e `MODULE`, `ENVIRONMENT`, `TAG`, `CI_CACHE_DIR`.

## Como rodar comandos do projeto (agentes e pessoas)

O ambiente correto é o container do módulo, com as dependências de pé pelo compose. Por isso:

1. **Existe target `make`? Use o target.** `make core.test`, `make core.lint`, `make core.db.migrate`, `make core.db.seed`, `make core.console`. `make help` lista tudo. Os scripts de `run/` rodam no serviço do módulo (`docker compose run --rm`), com o banco e os demais serviços de pé pelo `depends_on`.
2. **Não existe target? Rode dentro do container**, nunca no host: `docker compose --profile tools run --rm core <comando>` (ex.: `bin/rails runner '...'`, `bin/rails test test/models/x_test.rb`, `bundle exec rake lucid:tenancy:status`). Isso é o mesmo ambiente do `make`.
3. **Nunca rode `bundle`, `rails` ou `rake` direto no host** nem exporte `DATABASE_*`/`WARD_CONTEXT` à mão para fazê-los funcionar: isso testa outro ambiente (outra versão de gems, outro host de banco, sem o `ward` real) e esconde o que o dev vai encontrar. Se um comando só funciona no host com variáveis exportadas, o ambiente do container está errado e é isso que se conserta.
4. Argumentos: `make core.test ARGS="spec/models/x_spec.rb"`. Comando repetido que não tem target vira `run/<nome>` (e ganha target), não um one-liner colado em docs.
5. O trabalho termina com o ambiente pronto: banco migrado e populado no container, imagem de dev construída, `git status` limpo, para a próxima pessoa só rodar `make core.start`.

## Regras

- **O hook é a implementação.** `ci/checks/*.sh` tem a lógica; o make só o invoca. Nunca faça o hook chamar make.
- `run/<nome>` não pode ter nome reservado (`lint audit test build validate plan shell db keys remote secrets`): `make conform` reprova.
- `infra/ops/` só aceita `remote.sh` e `secrets.sh`.
- Target próprio do projeto vai em `.project/make/*.mk`, com prefixo `<módulo>.` (ex.: `core.account.status`), uma linha ou um script em `.project/scripts/` (1 script ↔ 1 target). Descrição com `## texto` aparece no `make help`.
- Lógica de mais de um comando nunca fica inline no Makefile.
- **Dependência de serviço não sobe pelo make** nem por wrapper shell ou função do commons: quem declara e sobe `database`, `mail` etc. é o `compose.yml` (`depends_on` com healthcheck), e o comando que precisa deles roda pelo compose (`br4zz4:docker`).
- `run/<nome>` que sobe processo (ex.: `run/start`) carrega o `.env` da raiz antes de chamar o Rails e exige as variáveis (`${WEB_PORT:?...}`): o `Dotenv` do Rails só carrega depois que o shell já expandiu os valores, e um default (`${PORT:-3000}`) esconde o erro.
- Nunca copie targets do commons para o projeto: ajuste o commons.
