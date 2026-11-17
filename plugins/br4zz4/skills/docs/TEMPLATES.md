# Templates (br4zz4:docs)

Templates por categoria. Leia antes de criar um doc novo e use o da categoria roteada.


### `rules/<scope>/`

```markdown
---
id: R-XXX
title: <título em português>
scope: <billing | membership | auth | ...>
certainty: high | medium | low
created: YYYY-MM-DD
updated: YYYY-MM-DD
---

# R-XXX — <Título>

> **TLDR**: uma frase descrevendo a regra e seu propósito.

## Given / When / Then

**Dado** [estado do sistema ou pré-condição]
**Quando** [evento ou ação que dispara a regra]
**Então** [resultado esperado ou comportamento do sistema]

## Tabela de decisão

> Use só quando a regra tem múltiplas condições. Remova esta seção para regras simples.

| Condição A | Condição B | Resultado |
|---|---|---|
| true | true | resultado 1 |
| true | false | resultado 2 |

## Restrições

- Nunca [o que é proibido]
- Sempre [o que é obrigatório]

## Teste vinculado

`test/caminho_test.rb` — "descrição do teste"
```

`R-XXX` é sequencial **por projeto** — consulte `docs/RULES.md` para o último ID.
Sem teste: `(sem teste ainda)`.

### `learnings/`

```markdown
---
title: <título em português>
scope: <habits | billing | auth | ...>
date: YYYY-MM-DD
certainty: high | medium | low
---

# <Título>

## O que aconteceu

<Um parágrafo com o sintoma do ponto de vista do usuário ou do comportamento do sistema>

## Causa raiz

<Motivo — regra de negócio, lógica, decisão de design ou comportamento técnico relevante>

## Correção

<O que foi mudado ou decidido e por quê>

## Como evitar

<Regra ou padrão que o time deve seguir para não repetir>
```

**Foco principal: regra de negócio.** Explique o comportamento do ponto de vista do
produto — o que aconteceu para o usuário, por que estava errado, como evitar. Detalhe
técnico é secundário. Evite jargão de código (nomes de classes, métodos, queries) no
título e nos parágrafos principais.

Learnings **não** entram em `RULES.md` — são separados das regras de negócio.

### `specs/`

```markdown
---
title: <título em português>
status: draft | proposed | in_progress | done | superseded
created: YYYY-MM-DD
updated: YYYY-MM-DD
owner: "@<handle>"
certainty: high | medium | low
---

# <Título>

> **TLDR**: uma frase — o que muda e por quê.

# what  — story + ## out of scope + ## acceptance criteria (Gherkin)
# why
# how
# definition of done
## documentation

Seção sem informação no original: `— (não registrado na spec original)`.

`draft` é o status de spec aprovada mas não iniciada, que vive em `specs/drafts/`. Ao começar
a implementação, mova para `specs/` e troque para `in_progress` — nunca implemente a partir de
um draft sem mover primeiro. `completed` não existe no enum; mapeie para `done`.

### `plans/` (legado — plan foi absorvido pela spec; novo plan nunca separado)

```markdown
---
title: <título em português>
spec: specs/<arquivo>.md
created: YYYY-MM-DD
updated: YYYY-MM-DD
certainty: high | medium | low
---

# <Título>

> **TLDR**: uma frase.

## Fases
## Verificação
```

`spec:` aponta para a spec correspondente, ou `null` se não houver.

### `features/`

```markdown
---
id: USER-XXX
title: <título em português>
scope: <domínio>
created: YYYY-MM-DD
updated: YYYY-MM-DD
certainty: high | medium | low
---

# USER-XXX — <Título>

> **TLDR**: uma frase.

## História

Como <persona>, quero <ação>, para <benefício>.

## Critérios de aceite

```gherkin
Cenário: ...
  Dado ...
  Quando ...
  Então ...
```
```

Não crie índice local (`features/INDEX.md` e afins) — o índice é único e fica em
`docs/README.md`. Nome em maiúscula viola a regra de nomes, e um índice por
categoria cria fontes que divergem.

Se um `INDEX.md` já existe e contém mais do que índice — roadmap, grafo de dependências,
glossário de domínio — o problema é o **nome**, não a existência. Renomeie para o que ele
é (`roadmap.md`), preservando o conteúdo.

O template acima é **estrutura mínima**, não camisa de força: quando a feature real tem
modelo de dados, endpoints e RBAC, adicione o frontmatter, o TLDR, a `## História` e
converta os critérios em Gherkin de verdade — e preserve as seções de domínio.

### `reference/<scope>/`

```markdown
---
title: <título em português>
scope: <domínio>
updated: YYYY-MM-DD
certainty: high | medium | low
---

# <Título>

> **TLDR**: uma frase.

## Visão geral
## Fluxo
## Contratos
## Referências
```

Use bloco ```mermaid``` na seção Fluxo quando o fluxo tiver mais de dois saltos.

### `guides/` e `architecture/`

```markdown
---
title: <título em português>
updated: YYYY-MM-DD
certainty: high | medium | low
---

# <Título>

> **TLDR**: uma frase.

## Pré-requisitos     (guides)
## Passos             (guides)
## Troubleshooting    (guides)

## Contexto           (architecture)
## Decisão            (architecture)
## Consequências      (architecture)
```

