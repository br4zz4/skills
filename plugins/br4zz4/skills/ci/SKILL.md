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
