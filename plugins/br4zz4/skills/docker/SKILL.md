---
name: docker
description: Use when creating or reviewing Docker files.
version: 4.1.0
---

# br4zz4:docker

> **TLDR**: o `compose.yml` do projeto inclui os fragments de serviços do `br4zz4/commons` (`database`, `mail`) e define o serviço do módulo. **Dependência é do compose**: `depends_on` com healthcheck, sem subir banco por make, wrapper ou função do commons. A imagem é uma só, gerada pelo commons (`commons build-image`) a partir de um Dockerfile genérico com scripts de customização por etapa; dev, staging e produção usam o mesmo comando.

## compose.yml

```yaml
include:
  - .commons/compose/database.yml
  - .commons/compose/mail.yml

services:
  core:
    profiles: [tools]
    image: <projeto>-core:dev
    working_dir: /source
    environment:
      DATABASE_HOST: database
      DATABASE_PORT: ${DATABASE_PORT}
      DATABASE_USERNAME: ${DATABASE_USERNAME}
      DATABASE_PASSWORD: ${DATABASE_PASSWORD}
    volumes:
      - ./modules/core/code:/source
      - ./.ward:/repo/.ward:ro
    depends_on:
      database:
        condition: service_healthy
```

- Compose ≥ 2.20 (`include:`). `make up` sobe com `--wait`; `make down` mantém os volumes.
- **Comandos sempre no container.** Com target `make`, use-o; sem target, `docker compose --profile tools run --rm <serviço> <comando>`. Nunca rode o app, os testes ou o `rake` no host (detalhes em `br4zz4:make`).
- **Dependências no compose.** O serviço do módulo declara `depends_on` com `condition: service_healthy`; o que precisa de banco roda pelo compose (`docker compose run --rm core ...`). Nunca orquestre dependência no Makefile, em script wrapper ou numa função do commons.
- Fragments: `database` (`postgres:16-alpine`), `mail` (`mailpit`, só local), `cache` (Redis, opt-in; Rails usa Solid Cache no Postgres e registra a exceção em ADR se precisar de Redis).
- **Sem default e sem prefixo.** Portas e credenciais vêm do `.env`, com erro se faltarem (`${DATABASE_PORT:?set DATABASE_PORT in .env}`): `DATABASE_PORT`, `DATABASE_USERNAME`, `DATABASE_PASSWORD`, `MAIL_PORT`, `SMTP_PORT`, `CACHE_PORT`. O nome diz o que é, não a implementação (`DATABASE_*`, nunca `DB_*`; `WEB_PORT`, nunca `SERVER_PORT`).
- **Mesma porta dentro e fora.** O servidor escuta na porta da variável (`postgres -p`, `redis-server --port`), então host e container usam o mesmo número e o serviço do módulo lê `${DATABASE_PORT}`, sem `5432` fixo. Porta diferente por projeto evita colisão (`port is already allocated`).
- O usuário e a senha do Postgres só valem na criação do volume: trocar `DATABASE_USERNAME`/`DATABASE_PASSWORD` depois exige recriar o volume (`down -v`, apaga os dados de dev) ou `ALTER USER`.
- O commons não monta `DATABASE_URL`: esse valor vem do escopo ward do ambiente. Em dev o app monta as URLs de banco, cache e cable a partir de `DATABASE_*`.
- `bin/init` do commons gera o `compose.yml` a partir dos `services` do `.github/modules.json` (`postgres`, `redis`).
- Serviço que o commons não oferece: o projeto o define no próprio `compose.yml`. Quando dois projetos repetirem o mesmo, ele vira fragment do commons.

## Imagem: um Dockerfile, no commons

Não há `Dockerfile` no módulo. O commons guarda `docker/Dockerfile.tmpl` e as stacks (`ruby`, `go`, `elixir`); o módulo só configura.

```
modules/<m>/code/.module/
  build.env                       # STACK=ruby, STACK_VERSION=3.4.7
  scripts/<etapa>.<NN>.<nome>.sh  # customização do projeto
```

- `commons build-image <módulo> <dev|release> [--tag T]... [--platform P] [--push]` é o único jeito de construir. O compose de dev, o hook `ci/checks/build.sh` (staging e produção) e o deploy usam o mesmo comando; o deploy nunca constrói.
- **Etapas:** `base` (runtime) → `tools` (compiladores) → `deps` (manifestos + dependências) → `dev` (ferramentas de dev) · `source` (código) → `release` (usuário, assets, `ENV`, `CMD`).
- **Scripts `<etapa>.<NN>.<nome>.sh`**: o número no meio faz a ordem de execução ser a ordem do `ls` (`base.10.system.sh`, `base.50.libvips.sh`). Passos de 10 no commons, `50` por convenção nos módulos. Os da stack rodam mesclados com os do módulo; o do módulo vence nome igual. Nome fora do padrão e script que falha abortam o build, e o log mostra qual script falhou.
- **Cache:** cada etapa copia só os próprios scripts; `deps` copia só os manifestos (`Gemfile`, `Gemfile.lock`), então o `bundle install` só reexecuta quando eles mudam. Em `dev` o código **não entra na imagem**: ele vem por volume (`./modules/core/code:/source`), então editar código nunca reconstrói. O `COPY . .` existe só na etapa `source` do `release`.
- `.dockerignore` do módulo exclui `.git`, `tmp`, `log`, `.ci-cache`, `.module`, `node_modules`, chaves e `.env`: um diretório de cache de 1 GB no contexto custa minutos por build.
- Sem segredos na imagem; eles chegam em runtime pelo provedor (Secret push). O `assets:precompile` do build roda sem as variáveis de runtime (`SECRET_KEY_BASE_DUMMY`).
- Shell interativo no container (`run/shell`): constrói a imagem de dev e roda `docker compose run --rm core zsh`; termina com status 0 (o status do último comando do shell não é erro do make).
- O build de produção é `linux/amd64`; em Mac `arm64` o aviso de plataforma de imagens `amd64` (ex.: `postgres`) é só emulação, não erro.
- Colima, não Docker Desktop: `exporting` e `unpacking` são lentos por E/S da VM; ajuste com `colima start --cpu N --memory N`. Nada disso sobe para o registry sem `docker push`.
