---
title: Skills br4zz4 como marketplace Claude com sync diário no qwert
status: in_progress
created: 2026-11-17
updated: 2026-11-17
owner: "@oporpino"
certainty: high
---

# Skills br4zz4 como marketplace Claude com sync diário no qwert

> **TLDR**: todas as skills saem de `~/.qwert/config/agents/skills` e passam a viver no repo público `br4zz4/skills`, num plugin Claude único `br4zz4` (cada skill vira `br4zz4:<skill>`). O claude.ai entrega essas skills no mobile, no app do Mac e no Claude Code. O qwert mantém uma cópia própria, sincronizada todo dia, e liga as skills no OpenCode com o mesmo id.

# what

Como dono das skills, quero manter uma fonte única em `br4zz4/skills` e usar as mesmas skills `br4zz4:<skill>` no app Claude (mobile e Mac), no Claude Code e no OpenCode, para não manter cópias divergentes em cada ferramenta.

Termos do domínio em `docs/CONTEXT.md` (Source, Synced copy, Daily sync, OpenCode link, Machine-local skill).

## out of scope

- Publicar no diretório oficial da Anthropic.
- `.claude/settings.json` declarando o plugin em cada repo de projeto. O Claude Code recebe as skills pelo sync da conta.
- `/plugin install` local no Claude Code CLI. Só o sync da conta, para não duplicar.
- Acompanhar o upstream das skills de terceiros. A partir desta spec, elas são conteúdo próprio do repo.
- Alterar o catálogo `br4zz4/qwert-recipes` ou o binário do qwert. A mudança fica no override local `~/.qwert/recipes`.
- CI no repo `br4zz4/skills`. A validação é local, via `make validate`.
- `loginctl enable-linger` no Linux. O timer usa `Persistent=true` e roda quando a sessão volta.
- Corrigir o link pendente `~/.config/opencode/commands`, que já está quebrado e não é afetado por esta spec.

## acceptance criteria

    Cenário: repo válido passa na validação
      Dado que plugins/br4zz4/skills contém só skills com name igual ao nome da pasta
      Quando rodo `make validate` na raiz do repo
      Então o comando sai com código 0 e lista a quantidade de skills validadas

    Cenário alternativo: nome inválido ou divergente
      Dado que uma skill tem name com ":" ou maiúscula, ou name diferente da pasta, ou mais de 64 caracteres
      Quando rodo `make validate`
      Então o comando sai com código diferente de 0 e cita o path da skill e a regra violada

    Cenário alternativo: description fora do limite
      Dado que uma skill não tem description ou tem description com mais de 1024 caracteres
      Quando rodo `make validate`
      Então o comando falha citando a skill

    Cenário alternativo: resquício de nome antigo ou de origem
      Dado que algum arquivo em plugins/ contém "oporpino:", "matt:", "qwert:" como prefixo de skill, ou as palavras "matt" ou "pocock" (sem diferenciar maiúsculas)
      Quando rodo `make validate`
      Então o comando falha citando arquivo e linha

    Cenário alternativo: manifest inválido
      Dado que .claude-plugin/marketplace.json ou plugins/br4zz4/.claude-plugin/plugin.json não é JSON válido ou não tem os campos obrigatórios
      Quando rodo `make validate`
      Então o comando falha citando o arquivo

    Cenário: skills disponíveis no app Claude
      Dado que o marketplace br4zz4/skills foi adicionado em Customize → Plugins com "Sync automatically" ligado
      Quando abro o chat no app mobile e no app do Mac e digito "/br4zz4"
      Então as skills br4zz4:* aparecem, incluindo br4zz4:spec e br4zz4:grilling

    Cenário: skills no Claude Code sem duplicata
      Dado que o Claude Code está logado na mesma conta Claude
      Quando rodo /skills
      Então cada skill br4zz4:* aparece uma vez só e nenhuma skill oporpino:*, matt:* ou qwert:* aparece

    Cenário: skill de máquina não é usada no chat
      Dado que br4zz4:qwert-ops tem compatibility e description começando por "Local machine only"
      Quando peço no chat do mobile algo genérico sobre o ambiente de desenvolvimento
      Então o Claude não carrega br4zz4:qwert-ops

    Cenário: primeira instalação no macOS e no Linux
      Dado uma máquina com opencode declarado e sem ~/.local/share/qwert/skills/br4zz4
      Quando rodo `qwert apply br4zz4-skills`
      Então o repo é clonado em ~/.local/share/qwert/skills/br4zz4
      E existe um symlink ~/.config/opencode/skills/br4zz4:<skill> para cada pasta em plugins/br4zz4/skills
      E o agendamento diário está ativo (launchd no macOS, timer systemd --user no Arch e no Debian)

    Cenário: migração do symlink antigo
      Dado que ~/.config/opencode/skills é um symlink para ~/.qwert/config/agents/skills
      Quando o sync roda pela primeira vez
      Então ~/.config/opencode/skills passa a ser um diretório real
      E ~/.qwert/config/agents/skills continua intacto
      E nenhum arquivo novo aparece no `git -C ~/.qwert status`

    Cenário: sync diário traz skill nova e remove skill apagada
      Dado que uma skill foi adicionada e outra removida em br4zz4/skills na main
      Quando o sync diário roda
      Então o link da skill nova existe e o link da skill removida não existe mais
      E links que não começam com "br4zz4:" não são tocados

    Cenário alternativo: cópia sincronizada alterada à mão
      Dado que alguém editou ou criou arquivo em ~/.local/share/qwert/skills/br4zz4
      Quando o sync roda
      Então a cópia volta exatamente para origin/main

    Cenário alternativo: sem rede
      Dado que o fetch falha
      Quando o sync roda
      Então os links existentes continuam como estavam, o erro vai para o log e o script sai com código diferente de 0

    Cenário alternativo: duas execuções simultâneas
      Dado que um sync está em andamento
      Quando outro sync é disparado
      Então o segundo sai com código 0 sem tocar em nada, registrando "locked" no log

    Cenário alternativo: Source intocada
      Dado que existem mudanças não commitadas em ~/workspace/br4zz4/skills
      Quando o sync roda
      Então nada em ~/workspace/br4zz4/skills muda

    Cenário: corte seco dos nomes antigos
      Dado que o corte foi aplicado no ~/.qwert
      Quando procuro "oporpino:", "matt:" e "qwert:" como nome de skill em ~/.qwert/config e ~/.qwert/mcp
      Então não há ocorrências
      E ~/.qwert/config/agents/skills não existe mais
      E a tool qwert_skill do MCP qwert continua devolvendo o conteúdo de br4zz4:qwert-ops

    Cenário: desfazer
      Dado que br4zz4-skills está instalado
      Quando rodo `qwert drop br4zz4-skills`
      Então os links br4zz4:* e o agendamento somem, e a cópia em ~/.local/share/qwert/skills/br4zz4 é removida

# why

Hoje as skills ficam presas no dotfiles (`~/.qwert/config/agents/skills`) e só o OpenCode da máquina enxerga. O app Claude no mobile e no Mac e o Claude Code não têm acesso, então o mesmo workflow (spec, grilling, tdd) não está disponível fora do terminal. O claude.ai aceita um repo GitHub como marketplace de plugins e propaga o plugin para chat, Cowork e Claude Code. Com isso, um repo público passa a ser a fonte única de todas as ferramentas. Além disso, as skills de terceiros hoje são cópias literais com nomes de origem, e o prefixo `br4zz4:` unifica a identidade do conjunto.

# how

Dois repos, ambos com `integration: main` (commit direto na main, sem PR) e `staging: none`. Cada fase é um conjunto coeso de commits que funciona sozinho; a ordem é obrigatória.

- **Feature flag:** não. O conteúdo novo é aditivo até a Fase 5, e o corte (Fase 5) é uma troca de nomes em configuração pessoal, sem usuário externo.
- **Telas:** sem telas.
- **Repos e caminhos:**
  - Source: `~/workspace/br4zz4/skills` → `git@github.com:br4zz4/skills.git` (público).
  - Synced copy: `~/.local/share/qwert/skills/br4zz4` (clone HTTPS `https://github.com/br4zz4/skills.git`, para funcionar sem chave SSH).
  - Dotfiles: `~/.qwert` → `oporpino/.qwert`.

## Mapa de nomes

Regra geral: `oporpino:<x>` → `<x>`, `matt:<x>` → `<x>`, `qwert:<x>` → `qwert-<x>`, com `:` interno virando `-`. Exceções:

| Origem | Destino |
|---|---|
| `oporpino:tdd` + `matt:tdd` | `tdd` (fusão) |
| `matt:ask-matt` | `which-skill` |
| `matt:setup-matt-pocock-skills` | `setup-repo` |
| `qwert-ops` | `qwert-ops` |
| `qwert:opencode-plugin` | `qwert-opencode-plugin` |
| `qwert:terminal:shortcut` (name atual `terminal-shortcut`) | `qwert-terminal-shortcut` |

**Machine-local skills:** `qwert-ops`, `qwert-opencode-plugin`, `qwert-terminal-shortcut`, `find-in-root`, `worktree`, `team`. Elas recebem:

- frontmatter `compatibility: Requires the user's own machine with qwert and OpenCode or Claude Code CLI; not for chat or cloud sessions.`
- description começando com `Local machine only: `.

Todas as outras skills ficam sem restrição, inclusive commit, pr e ci, porque o Claude Code na nuvem também commita.

## Fase 1 — Esqueleto do marketplace (repo: `br4zz4/skills`)

**Entrega:** estrutura do plugin, validação e publicação do repo vazio de skills (só uma skill-semente para a validação ter o que checar).

### Task 1.1: validação (TDD)
**Arquivos:** Create `scripts/validate.sh`, `Makefile` — Test `test/validate_test.sh`, `test/fixtures/valid/**`, `test/fixtures/invalid-*/**`
**Passos:** o tester cria fixtures (repo válido; name com `:`; name ≠ pasta; name > 64; description ausente; description > 1024; `matt` no corpo; `oporpino:spec` no corpo; marketplace.json quebrado) e `test/validate_test.sh`, que roda `scripts/validate.sh <fixture>` e confere exit code e mensagem → vermelho. Depois vem a implementação mínima de `scripts/validate.sh <root>` em bash portátil (sem flags GNU-only; `jq` para JSON). O script:
- percorre `plugins/*/skills/*/SKILL.md`;
- valida `name` contra `^[a-z0-9]+(-[a-z0-9]+)*$`, até 64 caracteres e igual à pasta;
- valida `description` entre 1 e 1024 caracteres;
- faz grep case-insensitive em `plugins/` de `matt` como palavra inteira (`grep -rniw matt`), de `pocock` e de `(oporpino|matt|qwert):[a-z]` (`grep -rniE`), sem `\b`, porque o grep do macOS não garante suporte;
- valida os dois manifests com `jq -e '.name and .plugins'` e `jq -e '.name'`;
- imprime `ok: N skills`.

O `Makefile` ganha `validate` (`scripts/validate.sh .`) e `test` (`bash test/validate_test.sh`). Ao final, os testes passam → commit `feat: add skill validation`.
**Valida:** `make test && make validate`

### Task 1.2: manifests e docs do repo
**Arquivos:** Create `.claude-plugin/marketplace.json`, `plugins/br4zz4/.claude-plugin/plugin.json`, `plugins/br4zz4/skills/which-skill/SKILL.md` (semente, reescrita na Fase 3), `README.md`, `AGENTS.md`, `THIRD_PARTY_NOTICES`, `.gitignore`
**Passos:**
- `marketplace.json` com `name: "br4zz4"`, `owner`, `plugins: [{ "name": "br4zz4", "source": "./plugins/br4zz4", "description": ... }]`.
- `plugin.json` com `name: "br4zz4"`, `description`, `version: "1.0.0"`.
- O `README.md` explica três coisas:
  - instalar no claude.ai: Customize → Plugins → Add marketplace `br4zz4/skills` → Add `br4zz4` → Sync automatically;
  - a estrutura do repo;
  - como criar uma skill e rodar `make validate`.

  Ele não cita a origem das skills.
- `AGENTS.md` com `## Integração` (`integration: main`), `## Staging` (`staging: none`) e a regra "toda skill nova passa em `make validate`".
- `THIRD_PARTY_NOTICES` com o texto integral da licença MIT da licença original das skills derivadas, para cumprir a cláusula de aviso. É o único arquivo fora de `plugins/` onde o nome aparece, e o validador não varre fora de `plugins/`.
- `claude plugin validate .`, se o CLI estiver disponível.
- Commit `feat: add br4zz4 plugin marketplace`.

**Valida:** `make validate` e `claude plugin validate .`

### Task 1.3: publicar o repo
**Ação externa — confirmar com o usuário antes:** `gh repo create br4zz4/skills --public --source . --remote origin --push`.
**Valida:** `gh repo view br4zz4/skills --json visibility --jq .visibility` retorna `PUBLIC`.

**Pronto para prod:** o marketplace é válido e instalável; não toca em nada do qwert.

## Fase 2 — Skills próprias (repo: `br4zz4/skills`)

**Entrega:** as 20 `oporpino:*` além de `tdd` (que fica para a Fase 3) e as 3 skills qwert, renomeadas conforme o mapa.
**Arquivos:** Create `plugins/br4zz4/skills/<novo>/**` copiando cada pasta de `~/.qwert/config/agents/skills/{oporpino/oporpino:*,qwert-ops,qwert:*}` com os arquivos auxiliares (`MULTI_MODULE.md`, `VISUAL.md`, `TEMPLATES.md`).
**Passos:**
- `name` = pasta nova.
- Toda referência a skill no corpo e nas descriptions passa a ser `br4zz4:<novo>`, conforme o mapa. Exemplo: `oporpino:patterns` cita `oporpino:architecture` e passa a citar `br4zz4:architecture`.
- As machine-local skills recebem `compatibility` e o prefixo na description.
- Referências a skills de terceiros já usam o nome final (`br4zz4:grilling` etc.), mesmo antes da Fase 3. As referências pendentes não quebram nada: uma skill que cita outra ausente só perde o atalho até a Fase 3.
- Commit `feat: migrate own skills to br4zz4`.

**Pronto para prod:** aditivo. O qwert ainda usa as skills antigas.
**Valida:** `make validate` e `ls plugins/br4zz4/skills | wc -l` = 24 (23 + a semente `which-skill`).

## Fase 3 — Skills de terceiros reescritas e tdd fundido (repo: `br4zz4/skills`)

**Entrega:** as 24 `matt:*` (todas menos `tdd`), reescritas e renomeadas, mais a `tdd` fundida.
**Arquivos:** Create/Modify `plugins/br4zz4/skills/<novo>/**`, com os auxiliares (`ADR-FORMAT.md`, `CONTEXT-FORMAT.md`, `DEEPENING.md`, `DESIGN-IT-TWICE.md`, `tests.md`, `mocking.md`, `UI.md`, `LOGIC.md`, `AGENT-BRIEF.md`, `OUT-OF-SCOPE.md`, `PHASE-BOUNDARIES.md`, `SKILL-MECHANICS.md`, `HTML-REPORT.md`, os `*-FORMAT.md` de `teach`, os `.md` de `setup-repo`, `scripts/hitl-loop.template.sh` de `diagnosing-bugs` e `template.sh` de `wizard`). Não copiar `agents/openai.yaml` nem `.skill-lock.json`.

**Regra de reescrita:** mesma intenção, mesmas etapas, regras, formatos de saída e gatilhos da description; muda a redação. A reescrita:
- reordena frases e troca exemplos genéricos por exemplos do contexto br4zz4 (Rails, qwert, OpenCode) quando isso não altera a regra;
- remove menções a autor, curso, newsletter ou repo de origem;
- renomeia termos de marca (marca de origem vira "br4zz4").

Nenhuma linha com 12 palavras ou mais pode ficar idêntica ao original.

**Fusão `tdd`:** base `oporpino:tdd`, que é a usada pelo tester e pelo techleader. Ela incorpora da outra:
- o gatilho "red-green-refactor" e "integration tests" na description;
- o conteúdo de `tests.md` e `mocking.md` como auxiliares;
- qualquer regra do loop red-green-refactor que a `oporpino:tdd` não tenha.

Em conflito entre as duas, vale a regra da `oporpino:tdd`.

**Passos:** reescrever skill por skill → `make validate` → checar similaridade com o comando abaixo → commit `feat: add rewritten workflow skills`.
**Pronto para prod:** aditivo.
**Valida:**
- `make validate`;
- `ls plugins/br4zz4/skills | wc -l` = 48;
- checagem de similaridade, sem saída esperada (só no momento da fase, não vai para o repo):

```bash
for f in $(cd ~/.qwert/config/agents/skills/matt && find . -name '*.md'); do
  awk 'NF>=12' ~/.qwert/config/agents/skills/matt/$f
done | sort -u > $TMPDIR/orig_lines.txt
grep -rhFxf $TMPDIR/orig_lines.txt plugins/br4zz4/skills
```

**Passo manual do usuário (depois do push):** no claude.ai, Customize → Plugins → Add marketplace `br4zz4/skills` → adicionar o plugin `br4zz4` → ligar "Sync automatically". Conferir no mobile e no app do Mac e, no Claude Code, `/reload-plugins` + `/skills`.

## Fase 4 — Recipe `br4zz4-skills` com daily sync (repo: `~/.qwert`)

**Entrega:** Synced copy, OpenCode links e agendamento diário. As skills antigas continuam visíveis via link `legacy`.

### Task 4.1: script de sync (TDD)
**Arquivos:** Create `bin/br4zz4-skills-sync` — Test `test/br4zz4-skills-sync_test.sh`
**Passos:** o tester escreve o teste com `HOME` temporário. O remote é um repo bare local, configurado pelas variáveis de ambiente `BR4ZZ4_SKILLS_REPO`, `BR4ZZ4_SKILLS_DIR`, `OPENCODE_SKILLS_DIR` e `BR4ZZ4_SKILLS_LEGACY`. Ele cobre os cenários de primeira execução, migração do symlink antigo, skill nova/removida, cópia alterada à mão, sem rede (remote inválido), lock ocupado, links não-`br4zz4:` preservados e Source intocada → vermelho.

Implementação (bash, macOS e Linux, sem `readlink -f`, `sed -i` nem `find -printf`):
1. Lock via `mkdir "$STATE/lock"`. Se já existir, registra `locked` e sai com 0. `trap` remove o lock.
2. Se `$DIR/.git` não existe, roda `git clone --depth 1 "$REPO" "$DIR"`. Senão roda `git -C "$DIR" fetch --depth 1 origin main`, depois `git -C "$DIR" reset --hard origin/main` e `git -C "$DIR" clean -fdx`. Se algo falhar, registra no log e sai com 1, sem tocar nos links.
3. Se `$OC` é symlink (`[ -L ]`), roda `rm "$OC"` (remove só o link). Depois `mkdir -p "$OC"`.
4. Para cada `$DIR/plugins/br4zz4/skills/*/`, roda `ln -sfn "<pasta>" "$OC/br4zz4:<nome>"`.
5. Para cada `$OC/br4zz4:*` cujo alvo não existe, roda `rm`.
6. Se `BR4ZZ4_SKILLS_LEGACY` aponta para um diretório existente, roda `ln -sfn "$BR4ZZ4_SKILLS_LEGACY" "$OC/legacy"`. Senão, remove `$OC/legacy` se for symlink.
7. Log em `${XDG_STATE_HOME:-$HOME/.local/state}/br4zz4-skills/sync.log`.

Defaults: `REPO=https://github.com/br4zz4/skills.git`, `DIR=$HOME/.local/share/qwert/skills/br4zz4`, `OC=$HOME/.config/opencode/skills`, `LEGACY` vazio. Commit `feat: add br4zz4 skills sync script`.
**Valida:** `bash test/br4zz4-skills-sync_test.sh`

### Task 4.2: agendamento e recipe
**Arquivos:**
- Create `recipes/br4zz4-skills/install.toml`, `recipes/br4zz4-skills/setup.toml`
- Create `config/br4zz4-skills/launchd/tech.br4zz4.skills-sync.plist`
- Create `config/br4zz4-skills/systemd/br4zz4-skills-sync.service`, `config/br4zz4-skills/systemd/br4zz4-skills-sync.timer`
- Modify `recipes/opencode/setup.toml`, `config.yml`

**Passos:**

`install.toml`, no padrão de `recipes/qwert-sync/install.toml`:
- `[meta]`: `type = "custom"`, `depends = ["git", "opencode"]`, `platforms = ["macos", "debian", "arch"]`;
- `[check]`: `command = "test -d $HOME/.local/share/qwert/skills/br4zz4/.git"`;
- `[install] all`: `~/.qwert/bin/br4zz4-skills-sync`;
- `[upgrade] all`: o mesmo comando;
- `[uninstall] all`: `rm -rf ~/.local/share/qwert/skills/br4zz4` mais a remoção dos `br4zz4:*` em `~/.config/opencode/skills`.

`setup.toml`, idempotente (o setup por comandos roda em todo `apply`):
- macOS: copia o plist para `~/Library/LaunchAgents/`, roda `launchctl bootout gui/$(id -u)/tech.br4zz4.skills-sync 2>/dev/null; launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/tech.br4zz4.skills-sync.plist`.
- Arch e Debian (chave `linux`): copia service e timer para `~/.config/systemd/user/`, roda `systemctl --user daemon-reload && systemctl --user enable --now br4zz4-skills-sync.timer`.
- `[undo]`: desfaz por plataforma (bootout + rm do plist; `disable --now` + rm das units + daemon-reload) e remove `~/.config/opencode/skills/br4zz4:*` e `~/.config/opencode/skills/legacy`.

Plist: `ProgramArguments` = `/bin/bash -lc "$HOME/.qwert/bin/br4zz4-skills-sync"`, `StartCalendarInterval` às 07:00, `RunAtLoad` true e `EnvironmentVariables.BR4ZZ4_SKILLS_LEGACY=$HOME/.qwert/config/agents/skills` (path absoluto expandido pelo setup com `sed` portátil para arquivo temporário + `mv`).

Service: `Type=oneshot` e `ExecStart=%h/.qwert/bin/br4zz4-skills-sync` com `Environment=BR4ZZ4_SKILLS_LEGACY=%h/.qwert/config/agents/skills`. Timer: `OnCalendar=*-*-* 07:00`, `RandomizedDelaySec=30m` e `Persistent=true`.

`recipes/opencode/setup.toml`:
- remover as linhas do link `skills` (`:10`, `:21`, `:32`);
- no `[undo]`, tirar `skills` do `rm -f` (`:42`, `:47`, `:52`), porque agora o diretório pertence ao br4zz4-skills.

`config.yml`: adicionar `br4zz4-skills` em `tools:` de todo profile que declara `opencode`.

Commit `feat: add br4zz4-skills recipe with daily sync`.

**Valida:**
- `qwert apply br4zz4-skills`;
- `ls -la ~/.config/opencode/skills` mostra o diretório real com `br4zz4:*` e `legacy`;
- `git -C ~/.qwert status --short` sem arquivos novos fora dos commitados;
- macOS: `launchctl print gui/$(id -u)/tech.br4zz4.skills-sync`;
- Linux: `systemctl --user list-timers br4zz4-skills-sync.timer`;
- no OpenCode, as skills `br4zz4:spec` e `oporpino:spec` aparecem as duas.

**Pronto para prod:** OpenCode passa a ter os dois conjuntos; nenhuma referência quebra.

## Fase 5 — Corte seco (repo: `~/.qwert`)

**Entrega:** só `br4zz4:*` existe.
**Arquivos:** Modify `config/agents/agents/techleader.md`, `config/agents/agents/spec.md`, `config/agents/agents/ask.md`, `config/agents/agents/reviewer.md`, `config/agents/agents/tester.md`, `config/opencode/AGENTS.md`, `mcp/qwert-mcp.mjs`, `config/br4zz4-skills/launchd/tech.br4zz4.skills-sync.plist`, `config/br4zz4-skills/systemd/br4zz4-skills-sync.service` — Delete `config/agents/skills/`
**Passos:**
- Trocar toda citação de skill para `br4zz4:<novo>` conforme o mapa.
- `mcp/qwert-mcp.mjs:14`: `SKILL_PATH` = `process.env.BR4ZZ4_SKILLS_DIR ?? join(homedir(), ".local/share/qwert/skills/br4zz4")` + `plugins/br4zz4/skills/qwert-ops/SKILL.md`.
- Remover `BR4ZZ4_SKILLS_LEGACY` do plist e do service. Com isso, o sync apaga o link `legacy` na próxima execução.
- `git rm -r config/agents/skills`.
- Rodar `qwert apply br4zz4-skills` e `~/.qwert/bin/br4zz4-skills-sync`.
- Commit `refactor: switch agent skills to br4zz4`.

**Valida:**
- `grep -rnE '(oporpino|matt|qwert):[a-z]' ~/.qwert/config ~/.qwert/mcp` sem saída;
- `test ! -e ~/.qwert/config/agents/skills`;
- `test ! -e ~/.config/opencode/skills/legacy`;
- tool `qwert_skill` do MCP qwert devolve o texto de `br4zz4:qwert-ops`;
- no OpenCode, só aparecem skills `br4zz4:*`.

## SEQUENCE

1. Fase 1 — esqueleto + publicação (`br4zz4/skills`)
2. Fase 2 — skills próprias (`br4zz4/skills`)
3. Fase 3 — skills reescritas + tdd + passo manual no claude.ai (`br4zz4/skills`)
4. Fase 4 — recipe e daily sync (`~/.qwert`)
5. Fase 5 — corte seco (`~/.qwert`)

Integração direto na main nos dois repos, nesta ordem.

# definition of done

- [x] Todo cenário de "acceptance criteria" foi validado (automatizado ou verificado com comando exato)
- [x] Testes automáticos passando — `make test` em `br4zz4/skills` e `bash test/br4zz4-skills-sync_test.sh` em `~/.qwert`
- [x] Toda task do "how" executada
- [x] Documentação atualizada (`README.md`, `AGENTS.md`, `docs/CONTEXT.md` em `br4zz4/skills`)
- [x] Staging: `staging: none` declarado no `AGENTS.md` dos dois repos
- [x] Cada fase validada isoladamente (validação e testes verdes sem as fases seguintes)
- [x] Última fase remove o código temporário (`legacy`, `BR4ZZ4_SKILLS_LEGACY`, `config/agents/skills`)
- [x] `make validate` sai com 0 e imprime `ok: 48 skills`
- [x] `test/validate_test.sh` cobre name com `:`, name ≠ pasta, name > 64, description ausente e > 1024, termos proibidos e manifest inválido, todos falhando com path e regra
- [x] `gh repo view br4zz4/skills --json visibility --jq .visibility` = `PUBLIC`
- [x] `THIRD_PARTY_NOTICES` presente; nenhuma ocorrência de `matt`/`pocock` em `plugins/` nem no `README.md`
- [x] Checagem de similaridade da Fase 3 sem saída
- [x] Uma única skill `tdd`, contendo `tests.md` e `mocking.md` e o gatilho red-green-refactor na description
- [x] As 6 machine-local skills têm `compatibility` e description começando com `Local machine only: `
- [ ] Usuário confirmou: `br4zz4:spec` aparece em `/` no chat do mobile e do app do Mac
- [ ] Usuário confirmou: pedido genérico no chat mobile não carrega `br4zz4:qwert-ops`
- [ ] `/skills` no Claude Code lista cada `br4zz4:*` uma vez e nenhuma skill com prefixo antigo
- [x] Teste do sync cobre: primeira execução, migração do symlink, skill nova/removida, cópia alterada, sem rede, lock, links alheios preservados e Source intocada
- [x] `qwert apply br4zz4-skills` ok no macOS; `launchctl print` mostra o job às 07:00
- [ ] `qwert apply br4zz4-skills` ok em Linux (Arch ou Debian); `systemctl --user list-timers` mostra o timer
- [x] Depois do apply, `git -C ~/.qwert status --short` não mostra arquivos gerados
- [ ] `qwert drop br4zz4-skills` remove links, agendamento e cópia
- [x] `grep -rnE '(oporpino|matt|qwert):[a-z]' ~/.qwert/config ~/.qwert/mcp` sem saída e `~/.qwert/config/agents/skills` removido
- [x] Tool `qwert_skill` do MCP qwert devolve `br4zz4:qwert-ops`

## documentation

- `br4zz4/skills`: `README.md`, `AGENTS.md`, `docs/CONTEXT.md` (glossário já criado com esta spec).
- `~/.qwert`: nenhuma doc nova; o `AGENTS.md` global de agentes só tem as citações trocadas na Fase 5.
