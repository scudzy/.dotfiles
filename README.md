# dotfiles

Personal dotfiles for **Windows 11 + WSL2** running Debian GNU/Linux 13 (trixie).

```
VERSION_CODENAME=trixie
DEBIAN_VERSION_FULL=13.2
```

## What's included

- **Zsh** - `.zshrc` loaded via `ZDOTDIR`, with `snippets/` split out by concern
- **[Zinit](https://github.com/zdharma-continuum/zinit)** - lazy-loading plugin manager;
  self-installs on first shell start and pulls most CLI tools from GitHub releases
- **Editor** - neovim (lua config, vim-plug); nano is available but unconfigured. **vim is deliberately not installed.**
- **Git** - aliases, delta pager, delta themes
- **Terminal** - oh-my-posh prompt, fastfetch greeting, bat/eza/fzf theming
- **tmux** - oh-my-tmux base config plus a local overrides file
- **fonts** - Powerline / Nerd Font families installed into `~/.local/share/fonts`

## Layout

The repo mirrors `$HOME`, so paths map 1:1 onto where the files end up:

```
~/.dotfiles/
|-- install.sh              # bootstrap for a fresh machine
|-- ANALYSIS.md             # design notes / repo audit
|-- zsh/                    # ZDOTDIR target: .zshenv .zshrc .zprofile .zlogin
|   |-- functions/          #   autoloaded custom functions
|   `-- completions/        #   extra _completion files
|-- snippets/               # sourced by .zshrc (aliases, options, fzf, xdg, ...)
|-- sh/                     # helper scripts, placed on PATH by .zshenv
|-- .config/                # XDG configs (bash, bat, eza, fastfetch, nvim, tmux, delta, ...)
|   |-- bash/               #   .bashrc .profile .aliases
|   `-- tmux/               #   tmux.conf (+ tmux.conf.local overrides)
|-- .local/share/           # fonts, gnupg configs, XFCE terminal color schemes
`-- etc/                    # system files: wsl.conf, wsl-distribution.conf, resolv.conf
```

### Editor

Neovim only. `EDITOR` and `VISUAL` in `zsh/.zshenv` point at `nvim`, and the
`v`/`vi` aliases resolve to `nvim`. `.vimrc`, `.gvimrc` and `.vim/` were
removed from this repo, and `vim`/`vim-gtk3` are no longer installed.

vim-plug for Neovim lives under `stdpath('data')` —
`~/.local/share/nvim/site/autoload/plug.vim` — **not** `~/.vim/autoload`, which
nvim never reads. `lua/plugins.lua` downloads it automatically on first start.

### How the shell is wired

This is **not** a GNU Stow layout. `zsh/.zshenv` sets:

```zsh
export DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
export ZDOTDIR="${ZDOTDIR:-$DOTFILES/zsh}"
```

so zsh reads `~/.dotfiles/zsh/.zshrc` **in place** - there is no `~/.zshrc`.
The only bootstrap file in `$HOME` is `~/.zshenv`, which just exports those two
variables. `/etc/zsh/zshenv` does the same for non-login shells and root.
Everything else is symlinked into `$HOME` by `install.sh`, so `git pull` takes
effect immediately.

## Quick start

```bash
git clone git@gitlab.com:scudzy/dotfiles-wsl.git ~/.dotfiles
cd ~/.dotfiles
./install.sh --help        # every option
./install.sh --dry-run     # print the full plan, change nothing
./install.sh               # interactive; pick a profile
```

### Options

| Flag | Effect |
|---|---|
| `-p, --profile NAME` | `minimal`, `shell` or `full` (default: ask) |
| `-n, --dry-run` | Print the complete plan and exit. Implies `--verbose`. |
| `-v, --verbose` | Narrate every check, including no-op decisions |
| `-q, --quiet` | Warnings, errors and summary only |
| `-y, --yes` | Answer yes to all prompts; defaults to profile `full` |
| `--skip-packages` | Symlink configuration only; install nothing via apt |

### Reading a dry run

`--dry-run` never mutates. Every command that *would* run is printed with a
`→` prefix and journalled by phase; the run ends with a grouped plan:

```
════════════════ PLAN ════════════════
  Shell extras                                     2  action(s)
  XDG configs                                      1  action(s)
  Fonts                                            3  action(s)
  ──────────────────────────────────────
  12 action(s) would run.

  Nothing was changed.  Re-run without --dry-run to apply.
```

Add `-v` to see per-package decisions (`✔ installed`, `⊘ provided by Zinit`).

Profiles:

| Profile | Installs |
|---|---|
| `minimal` | shell entry points only (`~/.zshenv`, `/etc/zsh/zshenv`, `chsh`) |
| `shell` | + apt packages, `.config/*`, fonts, oh-my-posh, `~/sh`  *(recommended)* |
| `full` | + neovim, tmux/TPM, git, XFCE color schemes, full package manifest |

Non-interactive: `./install.sh --profile full --yes`.

### Package handling

**apt never installs anything Zinit owns.** The two managers would otherwise
race for the same binary on `PATH`, and the copies would drift. `ZINIT_PROVIDES`
in `install.sh` is the single source of truth:

```
bat  chroma  delta  direnv  dust  eza  fastfetch  fd  fzf  gdu  gh
git-sizer  glow  grex  httpstat  hyperfine  jq  procs  rg  tldr  vivid
```

Anything in that table is filtered out *before* apt is consulted, whatever list
it appears in. This is enforced centrally in `pkg_install`, not by omitting
names from the manifests — so re-adding a name there still cannot install it.

The `full` profile's manifest holds 53 apt-managed packages. Each name is
checked with `dpkg -s` first; only missing ones are handed to `apt-get install`.
If a batch fails it retries package-by-package, so one bad name cannot block
the rest.

A few names are translated before apt sees them:

| You write | Installs | Why |
|---|---|---|
| `libtmux` | `python3-libtmux` | not a Debian package name |
| `gnupg2` | `gnupg` | `gnupg2` is a transitional alias |
| `dnsutils` | `bind9-dnsutils` | `dnsutils` has no candidate in trixie |

Use `--skip-packages` to do the linking only.

> **Note:** `rg` comes from Zinit, but `bash/.bashrc` sets
> `FZF_DEFAULT_COMMAND="rg --files"`. In a bash session (no Zinit on `PATH`)
> that only works once `rg` exists. If you rely on fzf-in-bash, log in to zsh
> once first, or keep `ripgrep` installed via apt.

The installer never overwrites: existing files are moved to
`~/.dotfiles-backup/<timestamp>/` first, and it finishes with a verification
pass that checks every path `.zshrc` expects and runs `zsh -n` over the
startup files.

## Manual steps after install

These need an interactive shell or sudo, so the installer only prints them:

1. **nvim plugins** - open `nvim` and run `:PlugInstall`
2. **tmux plugins** - start `tmux` and press `prefix` + `I` (caps i)
3. **WSL config** - `sudo cp ~/.dotfiles/etc/wsl.conf /etc/wsl.conf`, then run
   `wsl.exe --shutdown` from Windows
4. **Zinit first run** - the first `zsh` launch downloads ~40 plugins and
   binaries from GitHub releases; give it a few minutes

## Secrets

Nothing credential-bearing is committed. The following are intentionally
git-ignored and **not** linked by the installer:

| Path | Why |
|---|---|
| `.config/rclone/rclone.conf` | remote credentials (encrypted, but still) |
| `.config/copyq/*.dat` | clipboard history in plaintext |
| `.config/chezmoi/` | machine-local chezmoi state |
| `.config/gh/hosts.yml` | OAuth token for the GitHub CLI |
| `~/.env`, `*.gpg`, `.gnupg/`, `.ssh/` | general secrets |

If you fork this, **do not commit your own versions of these**. See
`.gitignore` for the full list.

## Notes

- These are personal configs; adjust paths and settings as needed.
- Back up existing dotfiles before running the installer (it does this for you).
- `etc/wsl.conf` sets `[automount] root = /`, so Windows drives appear as
  `/c`, `/d`, ... rather than `/mnt/c`. Adjust if you prefer the default.

## Authors

- [@scudzy](https://github.com/scudzy)

## License

[MIT](LICENSE)