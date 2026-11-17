---
name: cross-platform
description: Use when writing or reviewing any code, config, script, hook, or recipe in this repo — changes must always work on BOTH macOS and Linux (Arch/Hyprland). nunca escreva algo que quebre um dos dois lados.
---

# br4zz4:cross-platform

Contexto: este repo (qwert) sincroniza configs/skills/hooks entre máquinas **macOS (personal)** e **Arch Linux com Hyprland (work, root, server)**. Toda mudança tem que funcionar nos dois lados — não existe "só mexi no meu lado".

## Regras

1. **Detecte plataforma, nunca presuma.** Antes de escrever um script/comando, cubra os dois caminhos:
   - `case "$(uname)" in Darwin|Linux)` ou `if command -v pacman .../ command -v brew ...`
2. **Caminhos** — nunca hardcode:
   - `~` e `$HOME` são iguais nos dois lados; use-os sempre.
   - Config dir é `~/.config/...` no Linux e `~/Library/Application Support/...` em apps macOS — se o app diverge, resolva em runtime.
   - `/usr/lib/...` (Arch) vs `/opt/homebrew/...` (Apple Silicon) para paths de binário/site-packages: abstraia ou use `command -v`.
3. **Ferramentas divergentes:**
   - Package manager: `pacman` (Arch) vs `brew` (mac) — em recipes use as seções de plataforma do `install.toml`/`setup.toml` (`all` → `linux` → `macos`), nunca fallback direto pra debian.
   - `sed -i` precisa de argumento no macOS GNU-vs-BSD: use `sed -i ''` (mac) via detecção, ou prefira `perl -pi -e`.
   - `date`, `stat`, `grep -P`, `readlink -f` divergem — GNU vs BSD. Prefira alternativas portáveis (`realpath`, `grep -E`).
   - `killall`/`systemctl` não existem/lembram no macOS: `systemctl` só Linux; recarregue Hyprland com `hyprctl reload`.
4. **Hooks e zsh:** shell é `zsh` nas duas, mas hooks em `~/.qwert/hooks/zsh/{prepare,init}/` são escopados por diretório (`shared/`, `personal/`, `work/`, ...). Qualquer hook novo que interesse aos dois perfis vai em `shared/`.
5. **Keybinds / desktop:** remaps de teclado têm dois destinos — `keyd` (`/etc/keyd`, Linux) e macOS (Karabiner/HID) erklärt no skill `mac-hyprland`. Quando mudar um atalho, espelhar no outro lado (ou registrar que NÃO se aplica ao outro OS, com justificativa).
6. **Teste mental dos dois lados antes de commitar:** pergunte-se "isso roda no Arch?" e "isso roda no Mac?". Se não roda em algum, guard com detecção de plataforma — não com comentário "só funciona no X".

## Checklist antes do commit

- [ ] Script roda com `set -euo pipefail` nos dois OS
- [ ] Nenhum binário/presunção GNU-only ou macOS-only sem guard
- [ ] Hooks novos no diretório de escopo correto (`shared/` se ambos)
- [ ] Paths resolvidos via `command -v` / `$HOME` / runtime
- [ ] Mudança de keybind/config espelhada no outro OS se aplicável

## Verificação

```sh
# próprio lado
qwert doctor
# outro lado: após push, na máquina oposta
git -C ~/.qwert pull && qwert apply   # revisar status antes do apply
```
