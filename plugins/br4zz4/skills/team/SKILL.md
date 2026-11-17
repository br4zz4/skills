---
name: team
description: "Local machine only: Use to know the agent team roster, delegation matrix, model tiers and spec execution flow. Load before delegating or deciding whether to do a task yourself."
compatibility: Requires the user's own machine with qwert and OpenCode or Claude Code CLI; not for chat or cloud sessions.
version: 4.0.0
---

# br4zz4:team

> **TLDR**: Time de 7 agentes. O **techleader** (padrão) codifica e orquestra; só o **tester** edita teste; o **reviewer** revisa uma vez por spec. Regra: **faça você mesmo por padrão — delegar custa 3-10× mais**. Paralelize só tasks com arquivos disjuntos. O tier de modelo é da tarefa. **Latência primeiro, custo como teto.**

## Regra de ouro

Um subagente nasce com contexto frio: relê o código, devolve só um resumo. Custa 3-10× mais que uma operação direta. Antes de delegar: o contexto quente resolve mais barato? Se sim → faça você.

Delegue SÓ quando: (1) contexto isolado real, (2) paralelização real (arquivos disjuntos), (3) especialização (teste, revisão, busca).

## Roster

| Agente | Modo | Modelo | Papel | Edita |
|--------|------|--------|-------|-------|
| **techleader** | primary (padrão) | sonnet#medium | Codifica, orquestra, finaliza | tudo, menos teste |
| **builder** | subagent | sonnet#medium | Executa UMA task com lista de arquivos fechada | tudo, menos teste |
| **tester** | all | sonnet#medium | Red a partir do Gherkin; green 2× | SÓ teste |
| **reviewer** | subagent | opus#medium | Revisa diff + spec; read-only | nada |
| **explore** | subagent | haiku#low | Busca read-only | nada |
| **spec** | primary | opus#high | Entrevista e escreve specs | `docs/**` |
| **quick** | primary | haiku#low | Tarefas simples e diretas | tudo, menos teste |
| **ask** | primary | haiku#medium | Perguntas e respostas | nada |

"Menos teste" é regra de `permissions` (edit negado em `test/**`, `tests/**`, `__tests__/**`, `spec/**`, `*.test.*`, `*.spec.*`, `*_test.*`, `*_spec.*`), não só de prompt.

## Tiers de modelo (por tarefa)

| Tier | Modelo | Use para |
|------|--------|----------|
| T0 | haiku#low | busca, leitura, resumo, título, commit, chore com instrução fechada |
| T1 | sonnet#medium | código, testes, multi-step, UI, imagens |
| T2 | opus#high | spec, bug sem causa após 2 tentativas, segurança, revisão |

Escala um tier UMA vez se errar. `max` só a pedido. Cota Claude esgotada: opencode-go (T0 deepseek-v4.1-flash, T1 deepseek-v4-pro).

## Algoritmo de decisão

1. **Contexto quente resolve?** → faça você.
2. **Trivial?** (1 arquivo, <15 linhas, sem lógica nova) → faça você. Se nem o techleader é necessário → agente **quick**.
3. **Especialização?** → tester (teste), reviewer (revisão), explore (busca ampla), spec (planejamento). Tasks de arquivos disjuntos → builders em paralelo.

## Fluxo de execução de spec

Detalhado no prompt do **techleader**. Ordem: goal e todos → worktree → red (tester) → tasks → green + review em paralelo → DoD → finalização (`br4zz4:finish`, integra na main) → staging (alimentado pelo merge na main; ping nas telas criadas/editadas). Bug sem causa após 2 tentativas → recomendar `/model claude-agent/opus`. Sem spec ou trivial → sem reviewer.

## Regras de delegação

- **Background por padrão**; foreground só quando bloqueia E o tier é adequado. Sleep, idioma e comentários: `AGENTS.md` global.
- **Arquivos disjuntos**: duas tasks que tocam o mesmo arquivo ou dependem uma da outra rodam em sequência.

## Skills por agente

| Agente | Skills |
|--------|--------|
| techleader | `br4zz4:team`, `br4zz4:verify`, `br4zz4:finish`, `br4zz4:commit`, `br4zz4:patterns` |
| builder | `br4zz4:patterns` |
| tester | `br4zz4:tdd`, `br4zz4:commit` |
| reviewer | `br4zz4:check`, `br4zz4:cross-platform` |
| spec | `br4zz4:spec`, `br4zz4:grilling`, `br4zz4:domain-modeling` |
| quick | `br4zz4:commit` |
| ask | `br4zz4:find-in-root`, `br4zz4:vision` |
