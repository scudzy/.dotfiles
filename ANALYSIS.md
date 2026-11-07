# 📐 Dotfiles Architecture & Installer Specification

> **Target System:** Debian GNU/Linux 13 (Trixie) running under **Windows Subsystem for Linux 2 (WSL2)** on Windows 11.  
> **Repository Root:** `~/.dotfiles` (`$HOME/.dotfiles`)  
> **Core Shell:** Zsh 5.9+ with Zinit, Oh My Posh, and Neovim.

---

## 1. 🏛️ System Overview & Design Principles

This repository provides an automated, idempotent environment for Debian on WSL2. It is built around four fundamental principles:

1. **In-Place Execution over Symlink Forests**: Zsh is configured to run directly out of the cloned repository via `ZDOTDIR`. There is no symlinked `~/.zshrc`.
2. **Strict Package Ownership Isolation**: System tools are partitioned between the APT package manager and Zinit's GitHub release downloader. The two managers never manage or collide on the same binary.
3. **Guaranteed Dry-Run Accuracy**: The installer journals all planned mutations into a grouped, readable Plan without executing them or emitting false completion notices.
4. **Zero Data Loss**: Any pre-existing file or directory displaced during installation is safely relocated to a timestamped backup directory (`~/.dotfiles-backup/<timestamp>/`).

---

## 2. 🗂️ Filesystem Layout & Roles

The repository layout mirrors `$HOME`, ensuring transparent 1:1 mapping between git-tracked files and destination paths:

| Path | Role | Deployment Method |
|---|---|---|
| `zsh/` | ZDOTDIR root (`.zshenv`, `.zshrc`, `.zprofile`, `.zlogin`, `functions/`, `completions/`) | **In-place source** (read directly by Zsh via `ZDOTDIR`) |
| `snippets/` | Modular shell scripts sourced by `.zshrc` (`options`, `aliases`, `history`, `fzf`, `xdg`, `completion`) | Sourced directly from `$DOTFILES/snippets` |
| `sh/` | Standalone CLI utility scripts | Symlinked to `~/sh` and placed on `PATH` via `zsh/.zshenv` |
| `.config/` | XDG configurations (`nvim`, `tmux`, `fastfetch`, `bat`, `delta`, `eza`, `uv`, etc.) | Per-entry symlinking into `~/.config/` |
| `.local/share/` | Font families (Terminess Nerd Font, Powerline) and terminal themes | Per-entry symlinking into `~/.local/share/` |
| `etc/` | WSL and system templates (`wsl.conf`, `resolv.conf`, `zsh/zshenv`) | Manually copied or privileged install |
| `install.sh` | Main idempotent installer script | Bootstraps configuration, packages, and standalone tools |

---

## 3. 🐚 The In-Place `ZDOTDIR` Shell Architecture

The core shell configuration does **not** rely on symlinking `~/.zshrc`. 

### Bootstrapping Sequence
1. When Zsh launches, it evaluates `/etc/zsh/zshenv` and `~/.zshenv`.
2. The installer writes a minimal pointer block into `~/.zshenv`:
   ```sh
   # >>> dotfiles install.sh >>>
   export DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
   export ZDOTDIR="${ZDOTDIR:-$DOTFILES/zsh}"
   # <<< dotfiles install.sh <<<
   ```
3. Zsh sets its configuration directory (`ZDOTDIR`) to `~/.dotfiles/zsh`.
4. All subsequent startup files (`.zshrc`, `.zprofile`, `.zlogin`) are read **in place** directly from the repository.
5. `/etc/zsh/zshenv` is configured with the identical pointer, ensuring root subshells and non-login shells correctly resolve the repository's shell environment.

### Benefits
* No broken symlinks if files are added or renamed in `zsh/`.
* Running `git pull` updates the live shell configuration immediately.
* `$HOME` remains clean and uncluttered.

---

## 4. 📦 Three-Tier Package & Tool Orchestration

To avoid PATH conflicts, version drift, and package manager contention, tools are strictly segregated into three distinct management tiers:

```
┌─────────────────────────────────────────────────────────────┐
│                 Tooling Orchestration Model                 │
├──────────────────────────────┬──────────────────────────────┤
│ Tier 1: Zinit Owned Binaries │ GitHub release binaries      │
│                              │ (fastfetch, eza, fzf, etc.)  │
├──────────────────────────────┼──────────────────────────────┤
│ Tier 2: APT System Packages  │ Base OS & development tools  │
│                              │ (build-essential, git, etc.) │
├──────────────────────────────┼──────────────────────────────┤
│ Tier 3: Standalone Toolchain │ Upstream bootstrap scripts   │
│                              │ (oh-my-posh, uv, volta, etc) │
└──────────────────────────────┴──────────────────────────────┘
```

### Tier 1: Zinit Owned Binaries
Binaries installed by Zinit via GitHub releases are cataloged in `ZINIT_PROVIDES`:
```text
bat, chroma, delta, direnv, dust, eza, fastfetch, fd, fzf, gdu,
gh, git-sizer, glow, grex, httpstat, hyperfine, jq, procs, rg, tldr, vivid
```
`pkg_install()` filters out any package matching this list before invoking `apt-get`, guaranteeing that APT and Zinit never maintain competing copies of the same binary.

### Tier 2: APT System Manifest
System packages are installed through APT with defensive safeguards:
* **Pre-check**: Each package is checked using `dpkg -s`. Only missing packages trigger an `apt-get install` batch.
* **Debian 13 (Trixie) Package Translation**: Aliases reconcile distribution-specific names:
  * `libtmux` $\rightarrow$ `python3-libtmux`
  * `gnupg2` $\rightarrow$ `gnupg`
  * `dnsutils` $\rightarrow$ `bind9-dnsutils`
* **Isolated Batch Retries**: If a batch installation fails, `install.sh` falls back to package-by-package installation so that an unavailable or conflicting package never blocks the remaining set.

### Tier 3: Standalone Toolchain Engine
Tools that require upstream installers are managed via a centralized, declarative helper function `install_standalone_tool`:

```bash
install_standalone_tool "label" "binary_name" "fallback_binary_path" "confirmation_prompt" "install_command"
```

Each tool follows an identical idempotent lifecycle:
1. **Verification**: Checks if `have <bin>` succeeds or if the fallback binary path is executable.
2. **Flag Enforcement**: Skips installation if `--skip-packages` is passed.
3. **Interactive Confirmation**: Prompts the user (defaults to `y`; auto-accepts under `-y`/`--yes`).
4. **Execution & Failure Tracking**: Runs through `run_sh` for dry-run plan logging and records errors in `FAILED`.

#### Integrated Standalone Tools:
* **Oh My Posh**: Installed directly to `$HOME/.local/bin/oh-my-posh` without requiring root permissions.
* **Astral uv**: Installed via `curl -LsSf https://astral.sh/uv/install.sh | sh` for fast Python dependency management.
* **Rclone**: Upstream release installed via `curl -fsSL https://rclone.org/install.sh | sudo bash`.
* **Ookla Speedtest**: Official binary installed through the PackageCloud repository script and `apt-get`.
* **Volta**: Fast JavaScript runtime and package manager installed via `curl -fsSL https://get.volta.sh | bash`.

---

## 5. 🛡️ System Privileges & Security Architecture

### 1. Passwordless Sudo Drop-in (`/etc/sudoers.d/$USER`)
To prevent repeated sudo password prompts during long provisioning runs, `install_passwordless_sudo` provisions a secure drop-in configuration:
* Checks if `/etc/sudoers.d/$(id -un)` already exists and grants `NOPASSWD`.
* When installing, writes `$(id -un) ALL=(ALL) NOPASSWD:ALL` with mode `0440`.
* **Safety Verification**: Runs `sudo visudo -cf "$target"`. If syntax validation fails, the file is immediately removed to prevent locking the user out of `sudo`.

### 2. Sensitive Configs Filtering
The `link_dir` function strictly prohibits linking credentials or local state out of the repository. Any file or directory matching the following pattern is skipped:
```text
rclone | chezmoi | copyq | gh | gnupg | *.gpg | *token* | *secret* | hosts.yml
```
Stale symlinks matching these names are also pruned prior to directory linking.

---

## 6. 🎯 Profile Hierarchy & Matrix

The installer organizes installation into three progressive profiles:

```
[minimal] ────► [shell] ────► [full]
```

| Component | `minimal` | `shell` | `full` |
|---|:---:|:---:|:---:|
| Passwordless sudo (`/etc/sudoers.d`) | ✅ | ✅ | ✅ |
| Zsh Entry Point (`~/.zshenv`) | ✅ | ✅ | ✅ |
| System ZDOTDIR (`/etc/zsh/zshenv`) | ✅ | ✅ | ✅ |
| Login Shell Switch (`chsh -s zsh`) | ✅ | ✅ | ✅ |
| Core Shell Tools (`curl`, `git`, `unzip`, etc.) | — | ✅ | ✅ |
| Shell Extras (`pass`, `make`, build headers) | — | ✅ | ✅ |
| XDG Configs (`~/.config/*`) | — | ✅ | ✅ |
| Home Dotfiles (`.dircolors`, `.editorconfig`) | — | ✅ | ✅ |
| Helper Scripts (`~/sh`) | — | ✅ | ✅ |
| Fonts (Powerline & Terminess) | — | ✅ | ✅ |
| Standalone Tools (`omp`, `uv`, `rclone`, `speedtest`, `volta`) | — | ✅ | ✅ |
| Full APT Package Manifest (53 packages) | — | — | ✅ |
| Neovim + vim-plug (`stdpath('data')`) | — | — | ✅ |
| tmux + TPM (Tmux Plugin Manager) | — | — | ✅ |
| Git global config (`~/.gitconfig`) | — | — | ✅ |
| Terminal Color Schemes (XFCE) | — | — | ✅ |

---

## 7. 🔄 Execution Engine & Dry-Run Planning

The script avoids mutating the system during preview runs via a two-function abstraction layer:

* **`run "$@"`**: Executes shell commands directly or journals them to `PLAN_ROWS`.
* **`run_sh "$command"`**: Executes shell strings via `bash -c` or journals them to `PLAN_ROWS`.

### The Action Journal
Every modifying step appends `<phase>|<command>` to `PLAN_ROWS`. In `--dry-run` mode:
* Actual mutations are short-circuited.
* No false success messages (such as `✔ linked` or `✔ wrote`) are emitted.
* At script completion, `print_plan()` renders a grouped breakdown of pending actions by phase:

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

## 8. 💾 Symlink & Backup Subsystem

### Per-Entry Linking
`link_dir` iterates the contents of source directories rather than linking the top-level directory. For example, `~/.config/bat` is symlinked to `~/.dotfiles/.config/bat`, while `~/.config` remains a physical directory. This allows other tools to write to `~/.config` without dirtying or breaking the git repository.

### Circular Reference & Stale Link Safeguards
* **Canonical Path Resolution**: `readlink -f` verifies both the source and target. If a destination already resolves to the source, the link is confirmed and left untouched.
* **Self-Reference Guard**: Destination paths that point back into the source tree are skipped to prevent symlink loops.
* **Non-Destructive Backups**: When a target already exists as a regular file or non-symlinked directory, it is moved to `$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)/` before the link is created.

---

## 9. ✅ Health & Verification Subsystem

At the conclusion of the installation run, the `verify()` function validates system state:

1. **Path Presence**: Verifies essential runtime files exist:
   * `zsh/.zshrc`, `zsh/.zshenv`
   * `snippets/*.zsh` (all 10 modular zsh snippets)
   * Fastfetch theme templates (`archey.jsonc`, `examples/8.jsonc`)
2. **Zsh Syntax Compilation**: Runs `zsh -n` across all repository startup scripts to catch syntax regressions.
3. **Binary PATH Availability**: When running under `shell` or `full` profiles, verifies that `oh-my-posh`, `uv`, `rclone`, `speedtest`, and `volta` are resolvable on `PATH`.
4. **Summary & Error Reporting**: Accumulates failed operations in `FAILED` and exits with status code `1` if any step failed, providing a consolidated list of errors.
