# 🚀 dotfiles

Personal dotfiles optimized for **Windows 11 + WSL2** running **Debian GNU/Linux 13 (Trixie)**.

[![WSL2](https://img.shields.io/badge/WSL-WSL2-blue.svg?logo=windows&logoColor=white)](https://learn.microsoft.com/en-us/windows/wsl/)
[![Debian](https://img.shields.io/badge/Debian-13%20(Trixie)-D70A53.svg?logo=debian&logoColor=white)](https://www.debian.org/)
[![Shell](https://img.shields.io/badge/Shell-Zsh-green.svg?logo=gnu-bash&logoColor=white)](https://www.zsh.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## ✨ Features & What's Included

* 🐚 **Zsh + [Zinit](https://github.com/zdharma-continuum/zinit)** — In-place `ZDOTDIR` architecture with modular `snippets/` and fast, lazy-loaded GitHub release binaries.
* 💅 **Terminal & Prompt** — [Oh My Posh](https://ohmyposh.dev/) prompt theme, [Fastfetch](https://github.com/fastfetch-cli/fastfetch) ASCII greeting, and rich color palettes for `bat`, `eza`, and `fzf`.
* 📝 **Editor (Neovim)** — Lua-configured Neovim with automated `vim-plug` bootstrapping under `stdpath('data')`. *(Legacy Vim is intentionally purged).*
* 🪟 **Multiplexer (tmux)** — Based on `oh-my-tmux` with TPM (Tmux Plugin Manager) and custom overrides in `.tmux.conf.local`.
* 🐍 **Modern Python Tooling** — Superfast package and project management via Astral's [uv](https://astral.sh/uv).
* ⚡ **JavaScript Toolchain** — Seamless Node, npm, pnpm, and yarn version switching powered by [Volta](https://volta.sh/).
* 🌐 **Cloud & Networking** — Upstream [Rclone](https://rclone.org/) integration, official [Ookla Speedtest](https://www.speedtest.net/apps/cli) CLI, and network diagnostics.
* 🔤 **Typography & Fonts** — Powerline and Terminess Nerd Font families pre-configured in `~/.local/share/fonts`.
* 🛡️ **Automated Provisioning** — Robust, idempotent [`install.sh`](file:///\\wsl$\Debian\home\scudzy\.dotfiles\install.sh) with interactive profiles, grouped dry-run planning, and optional passwordless sudo configuration.

---

## 📂 Repository Layout

The repository mirrors `$HOME` so files map 1:1 onto where they live:

```text
~/.dotfiles/
├── 🚀 install.sh             # Bootstrap installer (idempotent, dry-run plan)
├── 📖 README.md              # Main documentation
├── 📐 ANALYSIS.md            # Technical architecture & design specification
├── 🐚 zsh/                   # ZDOTDIR target (.zshenv, .zshrc, .zprofile, .zlogin)
│   ├── functions/            # Autoloaded custom zsh functions
│   └── completions/          # Custom completions (volta, etc.)
├── 🧩 snippets/              # Modular zsh sources (aliases, options, fzf, xdg, ...)
├── 📜 sh/                    # Helper scripts (placed on PATH via .zshenv)
├── ⚙️ .config/               # XDG configurations
│   ├── bash/                 # Modular bash (.bashrc, .profile, .aliases)
│   ├── nvim/                 # Neovim configuration & lua plugins
│   ├── tmux/                 # tmux.conf & tmux.conf.local
│   ├── fastfetch/            # System fetch themes & configurations
│   └── ...                   # bat, eza, delta, uv, etc.
├── 🎨 .local/share/          # Fonts, terminal color schemes
└── 🏛️ etc/                   # WSL & system configs (wsl.conf, resolv.conf, zsh/zshenv)
```

---

## ⚡ Core Shell Architecture

> [!IMPORTANT]
> **Zsh is NOT symlinked to `~/.zshrc`.**

Instead of creating fragile symlinks in `$HOME`, `zsh/.zshenv` exports:

```zsh
export DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
export ZDOTDIR="${ZDOTDIR:-$DOTFILES/zsh}"
```

Zsh reads `~/.dotfiles/zsh/.zshrc` **directly in place**.
* The only bootstrap pointer file needed in `$HOME` is a tiny `~/.zshenv`.
* `/etc/zsh/zshenv` provides the identical pointer system-wide for non-login shells and root.
* All configuration changes are live instantly upon `git pull`.

---

## 🚀 Quick Start

Clone the repository and run the installer:

```bash
git clone git@gitlab.com:scudzy/dotfiles-wsl.git ~/.dotfiles
cd ~/.dotfiles

# 1. Preview every action without touching the system
./install.sh --dry-run

# 2. Run interactive installation (prompts for profile & options)
./install.sh
```

### 🎯 Install Profiles

| Profile | Description | What Gets Configured |
|---|---|---|
| `minimal` | Shell entry points only | `~/.zshenv`, `/etc/zsh/zshenv`, login shell (`chsh`), passwordless sudo |
| `shell` *(recommended)* | Complete CLI workstation | `minimal` + APT packages, `.config/*`, fonts, Oh My Posh, uv, Rclone, Speedtest, Volta, `~/sh` |
| `full` | Complete development suite | `shell` + Neovim, tmux + TPM, Git config, XFCE terminal color schemes, full package manifest |

For automated or unattended provisioning:
```bash
./install.sh --profile full --yes
```

---

## 🛠️ Installer Options & Flags

| Flag | Description |
|---|---|
| `-p, --profile NAME` | Select profile: `minimal`, `shell`, or `full` |
| `-n, --dry-run` | Print the exact grouped action plan and exit without modifying the system |
| `-y, --yes` | Answer "yes" to all prompts (defaults profile to `full`) |
| `-v, --verbose` | Narrate all decisions (including already installed/linked items) |
| `-q, --quiet` | Show progress, warnings, errors, and summary only |
| `--skip-packages` | Symlink configurations and shell entries only; skip package/tool installs |
| `-h, --help` | Display command usage and profile reference |

### 🔍 Grouped Dry-Run Planning

The `--dry-run` mode logs no false mutations. Every command that *would* run is journalled by phase and rendered into a high-level summary plan:

```text
════════════════ PLAN ════════════════
  Shell extras                                     2  action(s)
  XDG configs                                      1  action(s)
  Home dotfiles                                    2  action(s)
  Directories referenced by the zsh config         2  action(s)
  fastfetch themes (greeting needs archey.jsonc)   1  action(s)
  ──────────────────────────────────────
  8 action(s) would run.

  Nothing was changed. Re-run without --dry-run to apply.
```

---

## 📦 Package & Tooling Architecture

### 1. Zinit Ownership Isolation
APT never installs tools managed directly by Zinit from GitHub releases. `install.sh` enforces this centrally via `ZINIT_PROVIDES` before querying APT:

```text
bat  chroma  delta  direnv  dust  eza  fastfetch  fd  fzf  gdu  gh
git-sizer  glow  grex  httpstat  hyperfine  jq  procs  rg  tldr  vivid
```

This prevents version drift and dual-binary `PATH` conflicts.

### 2. Standalone Modern Toolchain
Fast standalone CLI tools are checked before installation and provisioned cleanly:

* 💅 **[Oh My Posh](https://ohmyposh.dev/)** — Installed to `~/.local/bin/oh-my-posh` without root dependencies.
* 🐍 **[Astral uv](https://astral.sh/uv)** — Fast Python package manager installed via `astral.sh/uv/install.sh`.
* ☁️ **[Rclone](https://rclone.org/)** — Latest upstream release installed via `rclone.org/install.sh`.
* 📶 **[Ookla Speedtest](https://www.speedtest.net/apps/cli)** — Official Ookla repository setup via PackageCloud.
* ⚡ **[Volta](https://volta.sh/)** — JavaScript runtime manager installed via `get.volta.sh`.

### 3. Passwordless Sudo
If not already active, the installer can write a dedicated drop-in file to `/etc/sudoers.d/$(id -un)` with `0440` permissions, validated with `sudo visudo -cf` before activating to guarantee safe syntax.

---

## 📋 Post-Installation Checklist

After running `install.sh`, complete these quick manual follow-ups:

1. **Neovim Plugins** 📝: Open `nvim` and run `:PlugInstall` (auto-bootstraps on first start).
2. **tmux Plugins** 🪟: Launch `tmux` and press <kbd>prefix</kbd> + <kbd>I</kbd> (Shift + i) to fetch TPM plugins.
3. **WSL Configuration** 🏛️: Apply custom performance and automount settings:
   ```bash
   sudo cp ~/.dotfiles/etc/wsl.conf /etc/wsl.conf
   ```
   Then restart WSL from PowerShell: `wsl.exe --shutdown`.
4. **Zinit Initial Sync** 🐚: The first time `zsh` starts, Zinit will automatically pull its configured plugins and binary shims.

---

## 🔒 Security & Secrets

> [!WARNING]
> Credential-bearing files are intentionally excluded from version control and will **never** be symlinked by `install.sh`:

| File / Pattern | Purpose |
|---|---|
| `.config/rclone/rclone.conf` | Remote cloud credentials |
| `.config/copyq/*.dat` | Plaintext clipboard history |
| `.config/chezmoi/` | Machine-local state |
| `.config/gh/hosts.yml` | GitHub OAuth access tokens |
| `~/.env`, `*.gpg`, `.ssh/`, `.gnupg/` | Private keys and environment secrets |

---

## 👤 Author

* **Scudzy** — [@scudzy](https://github.com/scudzy)

## 📄 License

This repository is licensed under the [MIT License](LICENSE).
