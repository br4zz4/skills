---
name: docker
description: Use when creating or reviewing Docker files.
version: 3.1.0
---

# br4zz4:docker

> **TLDR**: o `compose.yml` do projeto só inclui os fragments de serviços do `br4zz4/commons` (`database`, `mail`) e, se precisar, define os serviços próprios do projeto. O app roda no host com `mise`; não há stack, imagem nem serviço de dev no commons. O `Dockerfile` existe só para a imagem da release, construída pelo hook `build`.

## compose.yml

```yaml
include:
  - .commons/compose/database.yml
  - .commons/compose/mail.yml
```

- Compose ≥ 2.20 (`include:`). `make up` sobe com `--wait`; `make down` mantém os volumes.
- Fragments: `database` (`postgres:16-alpine`), `mail` (`mailpit`, só local). As mesmas imagens e credenciais dos serviços do CI.
- Sem Redis por padrão: cache e fila de projetos Rails usam Solid Cache e Solid Queue sobre o Postgres (`br4zz4:rails`). Projeto que precise de Redis inclui `.commons/compose/cache.yml` (`redis:7-alpine`, porta `COMMONS_CACHE_PORT`) e registra a exceção em um ADR.
- Portas por variável (`COMMONS_DB_PORT`, `COMMONS_MAIL_PORT`, `COMMONS_SMTP_PORT`). O commons não monta `DATABASE_URL`: esse valor vem do escopo ward de development do projeto.
- `bin/init` do commons gera o `compose.yml` a partir dos `services` do `.github/modules.json`.
- Serviço que o commons não oferece: o projeto o define no próprio `compose.yml`. Quando dois projetos repetirem o mesmo, ele vira fragment do commons.
- O commons não tem stacks nem variável de diretório: o caminho é `.commons/compose/<fragment>.yml`.

## Dockerfile

- Um `Dockerfile` por módulo, em `modules/<m>/code/`, para a **imagem da release** (stage final de runtime, sem ferramentas de dev). Não há target `dev`.
- A imagem é construída pelo hook `ci/checks/build.sh`, que recebe `TAG`. O deploy nunca constrói.
- Sem secrets na imagem; eles chegam em runtime pelo provedor (Secret push).
- Pin de versões de base alinhado ao `mise.toml` do módulo.
- O app local roda com `make <m>.start` (script `run/start`), não em container.
