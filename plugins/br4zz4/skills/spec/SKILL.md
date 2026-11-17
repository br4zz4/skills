---
name: spec
description: Use when the user asks to spec, plan, or document a change — the spec includes the implementation plan (tasks) and ends with a checkable checklist.
version: 5.0.0
---

# br4zz4:spec

> **TLDR**: Understand the problem through dialogue, propose approaches, then write the spec — `# what` (story, out of scope, acceptance criteria em Gherkin) → `# why` → `# how` (passo a passo completo) → `# definition of done` (checklist) — get approval and implement directly from it. There is no separate plan document.

## The Iron Gate

**NEVER write a spec, code, scaffold, or take any implementation action until you have completed the dialogue and the user has approved the spec.**

---

## Checklist (complete in order)

1. **Explore context** — read existing docs, recent commits, project structure
2. **Dialogue** — one question at a time until the problem is fully understood
3. **Propose 2–3 approaches** — with trade-offs and your recommendation
4. **Write spec** — save to `docs/specs/` at the repo root (always inside a category subfolder) in order: **`# what`** (story + `## out of scope` + `## acceptance criteria` em Gherkin) → **`# why`** → **`# how`** (passo a passo completo) → **`# definition of done`** (checklist), commit
5. **Self-review** — scan for gaps, contradictions, ambiguity; fix inline
6. **User approval gate** — wait for explicit approval before implementing
7. **Worktree** — always suggest a worktree in `<projeto>/.worktrees/<nome>` (via OpenCode) before implementing; `.worktrees/` must be in `.gitignore`

---

## Phase 1 — Explore context

Before asking anything, read:

- `docs/` — business rules, learnings, architecture of the current project
- `docs/features/` — existing user stories and Gherkin criteria (if they exist)
- `.commons/docs/` — cross-project guides, architecture and reference
- `docs/specs/` — existing specs so you don't duplicate decisions
- Recent git log: `git log --oneline -10`

`<docs-base>` = `docs` at the repo root (always with a category subfolder inside it — never
loose files in the `docs/` root).

For multi-module projects, read `docs/modules.md` to understand boundaries before scoping.

---

## Phase 2 — Dialogue

Ask one question at a time. Wait for the answer before asking the next.

Sequence:
1. "What problem are you solving or what do you want to change?" (overview)
2. "Which files or areas are involved?" — skip if already clear
3. Per part of the change: "What is part 1?" → "What is part 2?" → until the user says there are no more
4. "How do we verify this works?" — or infer it if obvious

During the dialogue, the user may raise doubts or explore trade-offs — engage, help them decide, incorporate conclusions into the spec. You are co-authoring, not just collecting answers.

**Scope check:** if the request describes multiple independent subsystems, flag it immediately. Don't spend questions refining an over-scoped problem — help the user decompose first, then brainstorm the first part.

---

## Phase 3 — Propose approaches

Present 2–3 distinct approaches with trade-offs. Lead with your recommendation and explain why.

Example structure:
- **Option A (recommended):** ...reason... trade-off: ...
- **Option B:** ...reason... trade-off: ...
- **Option C:** ...reason... trade-off: ...

Ask which to proceed with before writing the spec.

### Optional: visual companion

For genuinely visual decisions (UI layout, wireframe, architecture diagram, side-by-side directions), offer the browser companion; never force it, and skip it for conceptual or tradeoff questions. If the user accepts, read `VISUAL.md` in this skill's directory and follow it.

---

## Phase 4 — Write the spec

### File location

Default: inside the **primary project root** (never in `.commons`), under `docs/specs/` —
**always inside a category subfolder**, never loose in the `docs/` root.

```
<project-root>/docs/specs/YYYYMMDDHHMMSS_short_description.md
```

- `YYYYMMDDHHMMSS` = current timestamp
- `short_description` = English, snake_case, max 5 words
- Create the target folder (and `drafts/` beside it) if they don't exist
- Always **create a new file** — never overwrite a previous spec

### File format

Filename, frontmatter keys and **spec block headers** in English (`what`, `why`, `how`,
`definition of done`, `out of scope`, `acceptance criteria`, `documentation`) — body text
in Portuguese. This is the `br4zz4:docs` language rule applied to every doc under
`docs/`. Technical terms and code identifiers are never translated.

```markdown
---
title: <título em português>
status: proposed
created: YYYY-MM-DD
updated: YYYY-MM-DD
owner: "@<resolvido via `gh api user --jq '.login'`>"
certainty: high
---

# <Título>

> **TLDR**: uma frase — o que muda e por quê.

# what

A user story — uma story por spec, várias stories viram várias specs:

    Como <papel/persona>, quero <ação>, para <benefício>.

## out of scope

- O que esta mudança explicitamente NÃO faz. Encaixe ou consequência não pode ser descoberta no meio da implementação.

## acceptance criteria

Notação Gherkin, pensando em cenários alternativos: erro, borda, dados inválidos, plataforma (macOS/Linux).

    Cenário: <fluxo principal>
      Dado que <estado inicial>
      Quando <ação>
      Então <resultado observável>

    Cenário alternativo: <erro / borda / divergência>
      Dado que ...
      Quando ...
      Então ...

# why

<details que justificam a iniciativa> — por que vale esforço: problema de negócio real, dor, oportunidade ou dívida. Sem justificativa, não há spec.

# how 

Lista com o passo a passo para executar a spec — AQUI vai todo o detalhamento:

- tasks na ordem de execução, cada uma com **arquivos** afetados (paths exatos), **o que entrega** (uma responsabilidade por task) e **como validar** (comando exato de teste/build)
- task de código segue TDD: teste primeiro, depois implementação mínima
- **feature flag decidida**: toda spec responde "isto entra atrás de flag?". Mudança que troca ou liga uma área inteira (painel, fluxo de cobrança, auth) entra atrás de uma flag (Flipper) com ator definido, e o **último PR da sequência remove a flag**, o código antigo e as rakes de apoio. Spec sem flag declara o motivo ("mudança aditiva, invisível até ser usada")
- **telas criadas ou editadas** listadas com a rota de cada uma (ou "sem telas"), para o ping em staging
- **staging = merge na main:** o deploy em staging acontece ao mergear na `main` (a CI sobe a partir dela). A spec não prevê deploy manual; o passo de staging só ocorre depois da integração na main e o ping valida o resultado
- **sem placeholders**: nada de "TBD", "TODO" ou descrever sem mostrar como
- **agrupado em PRs sequenciais** (ver "Quebra em PRs sequenciais" abaixo): cada PR é uma fase com branch, base e critério de pronto próprios

Exemplo de task (indentada):

    ### Task N: <título>
    **Arquivos:** Create/Modify `<path>` — Test `<test/path>`
    **Passos:** teste que falha → implementação mínima → teste passa → commit `<type>: <desc>`
    **Valida:** `<comando exato>`

# definition of done

Checklist com o necessário para concluir a atividade **sem erros**. Base (obrigatória — não remova):

- [ ] Todo cenário de "acceptance criteria" foi validado (automatizado ou verificado com comando exato)
- [ ] Testes automáticos passando — suíte verde, não só a parte nova
- [ ] Toda task do "how" executada
- [ ] Documentação atualizada (ou "no doc changes" declarado)
- [ ] Staging: merge na main feito (é o que dispara o deploy) e todas as telas criadas/editadas respondem no ping (ou `staging: none` declarado no `AGENTS.md` do repo)

Se a spec tem PRs sequenciais, inclua também: `- [ ] Cada PR da sequência validado isoladamente (build e testes verdes sem os PRs seguintes)` e `- [ ] Último PR liga a funcionalidade e remove código temporário`.

Adicione itens específicos da spec conforme necessário — mas todo item é verificável
(por código, teste, comando ou cenário), nenhum item vago ("implementar direito")
e todo cenário Gherkin tem ao menos um item no DoD. O implementador confirma item a
item, marcando `- [x]` conforme verifica.

## documentation

Arquivos a criar ou atualizar em `<docs-base>/`, `ai/shared/rules/` ou `ai/shared/skills/`.
Se nenhum: "No doc changes."
```

`certainty: high` for a spec written now — the content comes from the dialogue with the user,
not from reconstruction. Use `medium` or `low` only when you inferred something from code that
the user did not state.

`status` values: `proposed` · `in_progress` · `done` · `superseded`. Never write `superseded`
without confirming the successor was actually implemented.

### Quebra em PRs sequenciais

Toda spec é entregue em **PRs empilhados**, em fases. O objetivo é coesão: cada PR faz uma
mudança coerente e entendível sozinha.

**Regras de quebra:**

1. **Coesão primeiro.** Cada PR mexe em UMA camada/estrutura. Ex.: primeiro a estrutura (schema,
   contrato, módulo), depois a camada de cima (serviço, endpoint, UI). Nunca misturar camadas no mesmo PR sem necessidade.
2. **Tamanho: alvo de 5 arquivos de código, teto (hard) de 10** (docs não contam). Coesão e
   atomicidade vêm antes do número: um PR de 7 arquivos coesos é melhor que dois PRs que quebram a unidade.
   Acima de 10, divida em PRs empilhados, mantendo cada um coeso e atômico.
3. **Cada PR funciona sozinho (hard rule).** Cada PR pode ir para produção sem o próximo.
   O build não quebra, os testes passam, o comportamento em prod não regride.
   - Se a feature depende de várias camadas, sobe a estrutura primeiro (código que ainda não é usado,
     ou atrás de flag/default que mantém o comportamento atual).
   - O **último PR liga tudo** (ativa a flag, conecta a camada, remove o código morto).
   - Nenhum PR pode existir só para "fazer funcionar" outro.
4. **Branches empilhadas.** PR 1 aponta para `main`. Cada PR seguinte tem como base a branch do PR
   anterior. A ordem de merge é a ordem da sequência. Cada PR entra por **merge normal** (padrão), ou
   squash/rebase quando o ruleset do repo pedir (ver `br4zz4:pr`).
5. **Cada PR da sequência é uma task em `# how`** com: branch, base, arquivos (paths exatos),
   o que entrega, critério de pronto para produção e comando de validação.

**Formato em `# how`:**

```markdown
## PR 1 — <título> (branch: `feat/<x>-1`, base: `main`)
**Entrega:** estrutura X (sem uso ainda)
**Arquivos:** Create/Modify `<path>` … (até 10)
**Pronto para prod:** <por que funciona sozinho>
**Valida:** `<comando exato>`

## PR 2 — <título> (branch: `feat/<x>-2`, base: `feat/<x>-1`)
…

## SEQUENCE
1. #<pr1> — <título>
2. #<pr2> — <título>
Merge in this order: #<pr1> #<pr2>
```

O `## SEQUENCE` acima segue o padrão do `br4zz4:pr` (`#<n>` ao abrir os PRs).

### Commit the spec

```bash
git add <docs-base>/specs/<filename>.md
git commit -m "docs: spec <short_description>"
```

`<docs-base>` = `docs` at the repo root.

---

## Phase 5 — Self-review

After writing, read the spec with fresh eyes:

1. **Placeholder scan:** any "TBD", "TODO", vague requirements? Fix them.
2. **Consistency:** do any sections contradict each other?
3. **Scope:** is this focused enough for one spec, or does it need decomposition?
4. **Ambiguity:** can any requirement be interpreted two ways? Pick one and make it explicit.
5. **Checklist coverage:** does the final "definition of done" item-map to every "acceptance
   criteria" (Gherkin) scenario and every "how" task? Any scenario or task without a
   DoD item is a gap.

Fix issues inline. No need to re-review — just fix and move on.

---

## Phase 6 — User approval gate

Show the user where the spec was saved, then:

> "Spec commitada em `docs/specs/<filename>.md`. Revise e me diz se quer alguma mudança antes de criar o plano de implementação."

Wait for explicit approval. If changes requested, update the spec, re-commit, run self-review again.

---

## Phase 7 — Worktree (always suggest)

After approval, **always** suggest creating a worktree before implementing. Do not ask whether
to do it — suggest it, with the exact steps below. The worktree lives inside the project:

```
<projeto>/.worktrees/<nome>
```

1. **Check the ignore:** confirm `.worktrees/` is in the project's `.gitignore`. If missing,
   add it and commit on its own: `chore: ignore .worktrees`. Never create a worktree before this is done.
2. **Create via OpenCode:** use the `worktree_create` tool with `name: <nome>` (the `<nome>` is the
   spec's short description). OpenCode places it in `<projeto>/.worktrees/<nome>` because the global
   config sets `worktree.directory: ".worktrees"`. Suggest the user runs it from the project root.
3. **Move the session:** after creating it, move the current session to the worktree directory
   (`session_move`) so the implementation runs there.

Then hand off to the **techleader** and implement **directly from the spec** — there is no separate
plan step. Give the user the ready-to-paste line (the `/goal` is a user command; the agent cannot
fire it):

```
/goal Implementar docs/specs/<arquivo>.md até o definition of done completo
```

The spec's final "definition of done" is the implementation contract: the techleader works through
it item by item, the tester writes the red tests from the Gherkin and runs the green suite
(`br4zz4:tdd`), and each item is ticked as it is verified.

Uma worktree por **pilha de PRs** (não por PR). Dentro dela, cada PR é uma branch empilhada sobre a
anterior, implementada e aberta na ordem da sequência. Não crie branches fora desse fluxo.

---

## Draft specs

Specs approved but not yet started go in `docs/specs/drafts/`:
- Status: `draft`
- Move to `<docs-base>/specs/` and change status to `in_progress` when implementation begins
- Never implement from a draft without moving it first

---

## Rules

- One question at a time during dialogue
- YAGNI: remove unnecessary scope from all specs
- Docker: before scoping any service change, apply `br4zz4:docker`
- If the change targets GitHub Actions, apply `br4zz4:ci`; reusable workflows live in `br4zz4/pipelines`, not commons
