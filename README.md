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
- **Editors** - vim (vim-plug), neovim (lua config), nano
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
|-- bash/                   # .bashrc .profile .aliases
|-- .config/                # XDG configs (bat, eza, fastfetch, nvim, delta, ...)
|-- .local/share/           # fonts, gnupg configs, XFCE terminal color schemes
|-- .vim/                   # vim-plug, colors, after/syntax
|-- .tmux/                  # .tmux.conf (+ .tmux.conf.local overrides)
`-- etc/                    # system files: wsl.conf, wsl-distribution.conf, resolv.conf
```

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
./install.sh --dry-run      # preview every action
./install.sh                # interactive; pick a profile
```

Profiles:

| Profile | Installs |
|---|---|
| `minimal` | shell entry points only (`~/.zshenv`, `/etc/zsh/zshenv`, `chsh`) |
| `shell` | + apt packages, `.config/*`, fonts, oh-my-posh, `~/sh`  *(recommended)* |
| `full` | + vim/nvim, tmux/TPM, git, XFCE color schemes |

Non-interactive: `./install.sh --profile full --yes`.

The installer never overwrites: existing files are moved to
`~/.dotfiles-backup/<timestamp>/` first, and it finishes with a verification
pass that checks every path `.zshrc` expects and runs `zsh -n` over the
startup files.

## Manual steps after install

These need an interactive shell or sudo, so the installer only prints them:

1. **Vim plugins** - open `vim` and run `:PlugInstall`
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