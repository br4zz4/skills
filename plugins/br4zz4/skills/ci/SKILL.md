---
name: ci
description: Use when creating or reviewing GitHub Actions files.
version: 3.0.0
---

# br4zz4:ci

## Pipeline padrão — `br4zz4/pipelines@v1`

Nenhum projeto escreve workflows à mão. O `conform` gera e verifica os três arquivos:

```
.github/workflows/
├── pr.yml      # pull_request → conform → detect → por módulo/lado: check/* → check/pr (gate)
├── main.yml    # push main → conform → detect → reuse → build → release
└── deploy.yml  # push tag (staging) ou dispatch em tag (staging|production)
```

Os três são **gerados** por `python3 actions/conform/render.py --root <projeto>` e nunca editados à mão. Qualquer divergência falha o `conform` no início do run.

### Estrutura de módulo

```
.github/modules.json               declaração de módulos e serviços
modules/<m>/code/
  mise.toml                        toolchain (Ruby, Node…)
  ci/checks/lint.sh · audit.sh · test.sh · build.sh
modules/<m>/infra/
  mise.toml                        toolchain (Terraform…)
  ci/checks/validate.sh · plan.sh
  ci/deploy/apply.sh · rollout.sh · verify.sh · rollback.sh
.github/actions/setup/action.yml   autenticação GCP (WIF) e pacotes de sistema
```

### Vocabulário fechado de hooks

| Contexto | Steps | Fase |
|---|---|---|
| `ci/checks/` | `lint`, `audit`, `test` | PR e main |
| `ci/checks/` | `validate`, `plan` | PR e main |
| `ci/checks/` | `build` | main (build da imagem) |
| `ci/deploy/` | `apply`, `rollout`, `verify`, `rollback` | deploy |

Cada hook é **obrigatório**. Um hook sem nada a fazer printa por quê e sai 0. Um script fora do vocabulário é rejeitado pelo `conform`.

O hook roda com o diretório do lado (`code/` ou `infra/`) como pwd e recebe `MODULE`, `ENVIRONMENT`, `TAG`, `CI_CACHE_DIR` e os secrets do escopo ward.

O hook é a implementação: o `make <módulo>.<step>` do `br4zz4/commons` roda o mesmo script localmente, com o mesmo pwd e as mesmas variáveis. Todo checkout dos reusables usa `submodules: recursive`, para o `.commons` estar disponível aos hooks de `apply` (`.commons/bin/commons secrets <módulo>`).

### Pipeline — fluxo resumido

```
PR     → conform → detect → módulos alterados: code (lint·audit·test) ∥ infra (validate·plan) → check/pr
main   → conform → detect → módulos: reuse (pula checks provados pelo PR) → build → release (tag)
tag    → deploy  → conform → releases → por módulo: preflight → apply → rollout → verify → record → notify
                                                                      └─► rollback (se rollout ou verify falhar)
dispatch em tag → mesmo fluxo, ambiente escolhido (staging padrão; production disponível)
dispatch em branch → falha sempre
```

### Nomes dos jobs

Formato `<módulo> / <job>`: `core / check / test`, `gateway / build`, `checkout / rollout`. Nenhum `name:` tem `${{`. Cada step é nomeado.

### Regras obrigatórias

- **Sem `secrets: inherit`** — secrets explícitos em todo caller de reusable.
- **Sem `strategy.matrix`** — cada módulo/step é um job literal.
- **Sem `environment:` em job** — só dentro do `deploy.yml` nos jobs de produção.
- **`if: always()`** em `notify` e no gate `check/pr`.
- **Rollback só quando `rollout` ou `verify` falharam** — `apply` não rola back.
- **Sem `_RESTRICTED` fora do `deploy.yml`** — a chave restrita fica só nos jobs de produção.
- **Runner:** `blacksmith-2vcpu-ubuntu-2404` (ou variante blacksmith). Nunca `ubuntu-latest`.

### Secrets — ward

O projeto mantém dois vaults:

```
<ns>::default    → secrets.ci.*, secrets.<m>.code.staging, secrets.<m>.infra.staging
<ns>::restricted → secrets.<m>.code.production, secrets.<m>.infra.production
```

GitHub recebe `WARD_KEY_<NS>` e `WARD_KEY_<NS>_RESTRICTED`. Nunca secrets colados à mão no GitHub.

### Como proceder

1. Leia `.github/modules.json` para saber os módulos e serviços.
2. Confirme o conjunto: exatamente `pr.yml`, `main.yml`, `deploy.yml` (mais `self.yml` só no `br4zz4/pipelines`).
3. Nunca edite os três workflows gerados — corrija `modules.json` ou os hooks.
4. Para gerar/conferir: `python3 actions/conform/render.py --root <projeto>`.
5. Para checar o contrato: `python3 tasks/check.py --standard .github/workflows`.


## Adotar o commons num repo existente

Ordem que funcionou (lunetamagica): submodule `.commons` em `v1` → `commons.ctx` → `Makefile` (`include .commons/make/main.mk`) → hooks → workflows gerados → secrets → proteção da main.

- **`run/` com nome reservado** (`lint audit test build validate plan shell db keys remote secrets`) reprova o `conform`: o conteúdo vira hook em `ci/checks/`. `compose.yml` vira só `include:` dos fragmentos do commons (postgres, redis, mail); o app roda no host via `mise`. Remova `makefile`, `.project/make/_main.mk` e o Makefile do módulo para não duplicar targets.
- **Hooks de infra**: um `ci/lib/env.sh` sourced por todos (projeto, prefixo, região, bucket do state, `TF_VARS`) evita copiar o mesmo `case` em seis scripts. O token do Cloudflare entra em `TF_VARS` a partir de `CLOUDFLARE_API_TOKEN` do escopo `infra`.
- **Hook `test`** prepara o que o ambiente limpo não tem: build dos assets (`tailwindcss:build`, o `tailwind.css` é gitignored) e o schema do banco. Config de teste nunca exige `REDIS_URL` (`ENV["REDIS_URL"].present?`, não `fetch`): o CI só sobe postgres.
- **Workflows offline**: `conform.py --mode fix` só escreve com `GH_PIPELINES_TOKEN`. Localmente, baixe `actions/conform/{conform,render}.py` do `pipelines@v1` numa pasta temporária e chame `render.render(render.load_project(root), "v1")`, gravando os três arquivos; depois `--mode check` deve dar `ok`.
- **Secrets**: `make github.setup` envia as chaves de `COMMONS_GITHUB_SECRETS` (arquivos `.ward/*.key` locais) como `WARD_KEY_<NS>` e `WARD_KEY_<NS>_RESTRICTED`, ajusta os merges para squash/rebase e cria o ruleset. Sem `WARD_KEY_<NS>` no repo, o `plan` falha com `no Google Cloud credentials`. `WIF_PROVIDER` e `DEPLOY_SA` não são secrets do GitHub: ficam no ward, em `secrets.<m>.infra.<env>` (valores = outputs do Terraform `github_ci`). O passo do ruleset pode quebrar em `gh` antigo (`gh repo view -R`); os secrets e o merge já foram gravados nesse ponto.
- **Proteção da main**: depois de trocar de pipeline, os checks exigidos antigos (`test`, `lint`, `audit`) não existem mais e o PR fica `BLOCKED`. Troque a exigência para `check/pr`: `gh api -X PATCH repos/<org>/<repo>/branches/main/protection/required_status_checks -F strict=true -f 'contexts[]=check/pr'`.
- **Repo transferido de org**: atualize `origin`, o `github_repository` do Terraform (condição do WIF) e aplique só `-target=module.github_ci`; sem isso a autenticação do deploy quebra. Transferir para uma org sem vaga de colaborador falha com `insufficient collaborator seats`; remova o colaborador (ex.: bot) e repita.
- **Agente**: `make <m>.*` e `github.setup` carregam o ward, que se recusa a ler em modo agente. Valide os hooks direto: `mise exec -C modules/<m>/code -- sh ci/checks/lint.sh`. Console remoto e `make core.remote` o usuário roda no terminal.
- **Depois do merge**: acompanhe `main` (build, release) e `deploy` (apply, rollout, verify, record) com `gh run watch`; só então ping nas telas. O deploy recebe `TENANT_BASE_DOMAIN` e demais envs do Terraform no `apply`.
