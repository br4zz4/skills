---
name: worktree
description: "Local machine only: Use when creating, moving, or removing git worktrees. Defines where worktrees live and how they must be named and ignored."
compatibility: Requires the user's own machine with qwert and OpenCode or Claude Code CLI; not for chat or cloud sessions.
version: 1.1.0
---

# Worktree

> **TLDR**: worktrees ficam sempre em `<projeto>/.worktrees/<nome>`, criados pelo OpenCode (`worktree_create`). O diretório `.worktrees/` deve estar no `.gitignore` do projeto antes de criar qualquer worktree.

## Regras

- Worktrees ficam em `<projeto>/.worktrees/<nome>` (caminho absoluto: `~/workspace/<projeto>/.worktrees/<nome>`). Sem exceção: não usar `~/.worktrees/`.
- Criar pelo OpenCode: `worktree_create({ name: "<nome>" })`. O destino depende de `worktree.directory: ".worktrees"` na config global (`~/.qwert/config/opencode/opencode.json`) — relativo ao checkout canônico do projeto.
- `.worktrees/` deve estar no `.gitignore` do projeto — verifique antes de criar; se faltar, adicione e commite (`chore: ignore .worktrees`). Nunca commitar worktrees.
- Branch segue o padrão do fluxo atual (ex: `traycer/<nome>` quando o subagente cria, ou `feat/<nome>` quando trabalho direto) — o nome da branch e o nome da worktree devem bater

## Criar

```bash
git -C <projeto> worktree add -b <branch> <projeto>/.worktrees/<nome> <base>
```

Subdiretórios `.worktrees/` e `.git/` do repo são criados automaticamente pelo git.

## Mover uma worktree para o padrão

Se uma worktree foi criada em lugar errado (ex: `~/.traycer/worktrees/`, raiz do workspace):

1. Vá para a worktree atual e commite o trabalho (ou use cherry-pick):

```bash
cd <worktree-atual>
git add -A && git commit -m "..."
```

2. Crie a worktree nova no padrão a partir da main:

```bash
git -C <projeto> worktree add -b <branch> <projeto>/.worktrees/<nome> <base>
```

3. Traga os commits (se a branch antiga não foi compartilhada):

```bash
cd <projeto>/.worktrees/<nome>
git reset --hard <base>
git cherry-pick <sha1>..<shaN>   # faixa dos commits da branch antiga
git submodule update --init --recursive   # se o projeto usa submodules
```

4. Remova a worktree antiga registrada no git. Se ela tem submodule, desative antes:

```bash
git -C <projeto> submodule deinit -f <caminho-da-wt-antiga>/.commons 2>/dev/null
git -C <projeto> worktree remove --force <worktree-atual>
git -C <projeto> worktree prune
rm -rf <worktree-atual>   # se sobrar diretório fantasma
# e se o git ainda listar a worktree antiga:
git -C <projeto> update-ref -d refs/heads/<branch-antiga> 2>/dev/null
```

## Integrar na main

```bash
cd <projeto>
git worktree list                      # confira o padrão
git checkout main && git pull
git stash push -u -m "wip pre-merge"   # se houver mudanças não-commitadas na main
git merge <projeto>/.worktrees/<nome>  # ou a branch
```

O merge pode ser fast-forward (commits direto) — confere com `git status -sb`.

**Stash:** só dê `git stash pop` num stash que você mesmo criou na mesma operação. `git stash` sem mudanças não cria nada, e o `pop` seguinte restaura um stash antigo do usuário, com conflitos. Rode `git stash list` antes e, se o pop conflitar, desfaça com `git reset --hard HEAD` (o stash é mantido) e avise o usuário.

## Verificação

- [ ] worktree está em `<projeto>/.worktrees/` ou `~/.worktrees/`
- [ ] `.worktrees/` presente no `.gitignore`
- [ ] branch da worktree bate com o nome da worktree
- [ ] nenhuma worktree fora do padrão registrada em `git worktree list`