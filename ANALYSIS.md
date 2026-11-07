# Dotfiles analysis & installer design

Generated from a read-only inspection of `~/.dotfiles` (`\\wsl.localhost\Debian\home\scudzy\.dotfiles`).

---

## 1. What the repo actually is

A single `$HOME`-style tree cloned to `~/.dotfiles`, targeting **Debian 13 (trixie) under WSL2**.
It is *not* a GNU Stow layout (no `stow/` package dirs) — it is a flat "copy of `$HOME`" with
a handful of subfolders that the shell sources in place.

| Path | Files | Role |
|---|---|---|
| `.config/` | 207 | XDG configs (bat, fastfetch, eza, nvim, delta, powerline, …) |
| `.local/share/fonts/` | ~160 | Nerd/Powerline fonts + XFCE terminal colour schemes |
| `zsh/` | 36 | `ZDOTDIR` target: `.zshrc`, `.zshenv`, `.zprofile`, `.zlogin`, `functions/`, `completions/` |
| `sh/` | 31 | Utility scripts — put on `PATH` via `.zshenv` |
| `snippets/` | 11 | Sourced by `.zshrc` via `$DOTFILES/snippets` |
| `.vim/` | 8 | vim-plug, colours, after/syntax |
| `.tmux/` | 3 | `.tmux.conf` (oh-my-tmux), `.tmux.conf.local` |
| `bash/` | 3 | `.bashrc`, `.profile`, `.aliases` |
| `etc/` | 5 | `wsl.conf`, `wsl-distribution.conf`, `resolv.conf`, `apt/sources.list`, `zsh/zshenv` |
| `gitstatus/` | 3 | `gitstatusd` binary (zsh git prompt) |

Root-level dotfiles: `.gitconfig`, `.vimrc`, `.gvimrc`, `.nanorc`, `.dircolors`, `.editorconfig`,
`.zlua`, `.gemrc`, `.cczerc`, `.pythonrc`, `.tioconfig`, `.gdu.yaml`.

> `node_modules/` (gitmoji-cli via pnpm) is present in the working tree but excluded from all
> installer operations.

---

## 2. The key finding: zsh is **not** symlinked

`zsh/.zshenv` line 3:

```zsh
export ZDOTDIR="${ZDOTDIR:-$DOTFILES/zsh}"
```

zsh therefore reads `~/.dotfiles/zsh/.zshrc` **directly**. There is no `~/.zshrc` to manage.

`~/.zshenv` is the *only* bootstrap file that must exist in `$HOME`, and all it needs is:

```sh
export DOTFILES="$HOME/.dotfiles"
export ZDOTDIR="$DOTFILES/zsh"
```

This is why a naive "symlink everything to `$HOME`" installer is the wrong approach — it would
create `~/.zshrc` that zsh never reads, and can conflict with `git/.tmux` naming the README
mentions but which don't exist.

`etc/zsh/zshenv` handles the case where `~/.zshenv` is bypassed (non-login shells, `sudo -s`, root).

---

## 3. External dependencies (what a fresh clone is missing)

**From `zsh/.zshrc` — self-installing, no action needed:**
- Zinit (`~/.local/share/zinit/zinit.git`) — cloned automatically on first shell start.
- ~40 plugins + binaries pulled by Zinit (`gh-r` releases): fd, bat, delta, gh, jq, fzf, eza,
  ripgrep, fastfetch, dust, gdu, tealdeer, direnv, z.lua, forgit, fzf-tab, …
  These download on first launch and take a few minutes.

**Must be installed by the system:**
- `zsh` (login shell), `git`, `curl`
- `locale` **en_US.UTF-8** — `.zshenv` exports `LC_ALL=en_US.UTF-8`; missing → warning spam
- `oh-my-posh` at `~/.cache/oh-my-posh/themes/pure.omp.json` (referenced by `.zshrc` line 288)
- `fastfetch` with `.config/fastfetch/archey.jsonc` and `examples/8.jsonc`
- A Nerd Font (MesloLGS NF / Terminess) for prompt + `eza --icons`
- `bat`, `eza`, `fzf`, `ripgrep` (some Zinit also provides — apt versions are safer)
- `grc` + `/etc/grc.zsh` (`.zshrc` line 227 sources it; guarded by existence)
- `pass`, `rclone`, `gnupg` for password-store aliases
- `tmux` + TPM for `.tmux.conf`
- `vim` + vim-plug + `:PlugInstall`; `nvim` for `.config/nvim`
- `~/.local/state/zsh/.zsh_history` dir (HISTFILE)

---

## 4. Problems found in the current repo

These are pre-existing issues the installer works around, but they're worth fixing at the source:

| Issue | Detail | Installer behaviour |
|---|---|---|
| **Secrets in a public repo** | `.config/rclone/rclone.conf` (remote credentials), `.config/copyq/copyq.pub` (+ `.dat` clipboard history), `.config/chezmoi/chezmoistate.boltdb`, `.config/navi/navi.log`. `.gitignore` covers `.aws/`, `hosts.yml` etc. but **not these**. | `link_dir` skips `rclone`, `chezmoi`, `copyq`, `gh`, `gnupg`, `*.gpg`, `*token*`, `*secret*`, `hosts.yml` |
| **Hard-coded `$HOME`** | `.gitconfig` includes `/home/scudzy/.config/delta/themes.gitconfig`; `.zshrc` sets `PNPM_HOME='/home/scudzy/...'`; `bash/.bashrc` uses `${HOME}` correctly. | warns if `$HOME` doesn't match |
| **`sh/installzsh.sh` is a destructive stub** | `sudo cp -r <repo_name>/* /` — copies over the whole filesystem root, with placeholder `<username>`. | not used; left untouched |
| **`sh/symlink.sh` is stale** | Hard-coded `/home/scudzy/...`, references a non-existent `.gitconfig.user`, and symlinks `zsh/.zshrc` → `~/.zshrc` which zsh ignores. | superseded by `install.sh` |
| **README structure is fictional** | Documents `zsh/ zinit/ git/ tmux/ vim/ etc/ sh/` — real tree has no `git/` or `zinit/`, uses `.tmux/` and `.vim/` (dot-prefixed). | — |
| **`.gitignore` is self-defeating** | Ignores `package.json`, `.pre-commit-config.yaml`, `*gitleaks*.toml`, `*/plugins/`. `package.json` and `.pre-commit-config.yaml` are nonetheless tracked. | — |
| **Duplicate/legacy files** | `.config/wget/wgetrc` **and** `.wgetrc`; `.config/readline/inputrc` **and** `.inputrc`; `.config/fastfetch/{presets/,examples/}` duplicated at top level; `trace.log`, `fastfetch.jsonc.old`, `.zcompdump*`. | `.log`, `.zcompdump*` excluded from linking |

---

## 5. Installer design (`install.sh`)

```
./install.sh                        # interactive, asks profile
./install.sh --dry-run              # prints every action; changes nothing
./install.sh --profile full --yes   # unattended
```

**Idempotent & safe by construction**

- Re-running is a no-op for anything already linked.
- A real file at a destination is **moved** to `~/.dotfiles-backup/<timestamp>/` (never deleted, never silently replaced).
- A stale symlink is replaced; a correct one is reported as "already linked".
- `--dry-run` short-circuits every mutating call through `run`/`run_sh`.
- Refuses to run as root, refuses to clone into a non-empty non-repo directory.

**Three profiles**

| Profile | Does |
|---|---|
| `minimal` | clone/pull, `~/.zshenv` ZDOTDIR block, `/etc/zsh/zshenv`, `chsh -s zsh` |
| `shell` | + apt packages, `.config/*` links (secrets skipped), home dotfiles, bash wiring, fastfetch, fonts, oh-my-posh, `~/sh` |
| `full` | + vim/nvim/vim-plug, tmux/TPM, git, XFCE colour schemes, WSL follow-up notes |

**Link strategy: per-entry, not whole-directory**

`link_dir` links each child of a source dir into the destination. So `~/.config/bat` is a symlink
to `~/.dotfiles/.config/bat`, but `~/.config` itself stays a real directory and unrelated
tool-created configs (e.g. `~/.config/Code`) keep working. This avoids the classic
"whole `~/.config` is one symlink" problem.

**Verification step**

Checks every path `.zshrc` assumes exists (`snippets/*.zsh`, `archey.jsonc`, `examples/8.jsonc`,
`zsh/.zshenv`) and runs `zsh -n` over all zsh startup files, reporting failures in the summary
with a non-zero exit.

**Output**

Every run ends with a summary: links created, skipped, failures, backup location, and a
"Manual follow-ups" list (`:PlugInstall`, `prefix + I` for TPM, `wsl.conf` copy).

---

## 6. Follow-ups (applied)

All of the previously recommended fixes have been carried out:

| # | Fix | Status |
|---|---|---|
| 1 | Untrack secrets; rotate credentials; purge history | **Untracked + git-ignored.** Files remain on disk, now ignored. History purge still needs a manual `git filter-repo` + force-push (see below). |
| 2 | Replace `/home/scudzy` with portable paths | **Done** in `.gitconfig` (`~/.config/delta/...`), `.zshrc` (`$HOME`), `snippets/aliases.zsh` (`${DOTFILES:-$HOME/.dotfiles}`, dropped the `HOME="/home/scudzy"` override), `bash/.profile`, `bash/.bashrc`, tealdeer, wget, gpg, tmux-resurrect. |
| 3 | Delete `sh/installzsh.sh` and `sh/symlink.sh` | **Deleted** (no remaining references). |
| 4 | Rewrite README structure section | **Rewritten** to match the real tree and the `ZDOTDIR` wiring. |
| 5 | Fix `.gitignore` over-ignores | **Done** — no longer ignores `package.json`, `pnpm-lock.yaml`-adjacent entries, `.pre-commit-config.yaml`, or `*gitleaks*.toml`. Those files were never actually committed; they are now staged. |
| 6 | Remove `trace.log`, `*.zwc`, `*.jsonc.old` | **Removed** `trace.log`, `zsh/.zcompdump*`, `.config/fastfetch/fastfetch.jsonc.old`, and `.zlua` (machine-specific jump cache). |

Additional cleanups found while applying the above:

- `bash/.bashrc` did `source /home/scudzy/dotfiles/.zsh/.zshrc` — a path that does
  not exist (wrong dir name **and** no `.zsh` dir). Removed; bash never needed to
  source zsh config. `gh completion` is now guarded with a `command -v` check.
- `.config/chezmoi/chezmoi.yaml` pointed every tool at `/home/scudzy/...` and
  duplicated machine state. chezmoi is not used by this setup, so the file was
  removed along with the boltdb state.
- `install.sh` clone URLs corrected to the real remote
  (`gitlab.com/scudzy/dotfiles-wsl.git`, GitHub mirror `dotfiles-wsl`).
- `install.sh` no longer links `.zlua`.

### Still manual — history purge

The secret files were committed in earlier history. Untracking stops future
leaks but the blobs are still in the GitLab repo history. To purge:

```bash
pip install git-filter-repo
cd ~/.dotfiles
git filter-repo --invert-paths \
  --path .config/rclone/rclone.conf \
  --path .config/copyq/copyq_tab_JmNsaXBib2FyZA==.dat \
  --path .config/copyq/copyq.pub \
  --path .config/chezmoi/chezmoistate.boltdb
git remote add origin git@gitlab.com:scudzy/dotfiles-wsl.git
git push --force --all
```

`main` is a protected branch on GitLab, so the force-push needs protection
temporarily lifted. **Rotate any rclone remote credentials** regardless —
assume the encrypted config was downloadable.

### Remaining known smells (not fixed)

- `.config/powerline/` contains only upstream theme defaults — effectively dead.
- `sh/tarhome.sh` still hard-codes `/home/scudzy/` as a source dir; it is a
  one-off personal backup script, so it was left alone.
- `zsh/completions/_myfunc` hard-codes a Windows VS Code path.
- `etc/wsl.conf` sets `[automount] root = /`, which is intentional but
  non-default; documented in the README.
## 7. Full-profile package manifest

The `full` profile installs a curated 56-package list, checked one by one:

```sh
./install.sh --profile full          # dry-run first: add --dry-run
```

Behaviour:

- **Per-package check** via `dpkg -s`; only missing packages hit `apt-get`.
- **Name aliases** for `libtmux` -> `python3-libtmux`, `gnupg2` -> `gnupg`,
  `dnsutils` -> `bind9-dnsutils` (the last has no candidate in trixie).
- **Isolated retry**: a failed batch is retried package-by-package so a single
  bad name cannot abort the rest.
- **Not-in-repo names** are reported separately instead of failing the run.
- **Zinit-provided tools** (`httpstat`, `tldr`, `fd`, `bat`, `delta`, `gh`,
  `jq`, `fzf`, `eza`, `rg`, `fastfetch`, `dust`) are skipped for apt because
  `.zshrc` installs them; they are listed as such, not as errors.

### Link bug found during live testing

The first real (non-dry) install exposed a serious bug in `link_dir`. When
linking `~/.config/fastfetch`, the destination became a symlink into the
source, and the next `link_dir` call iterated `"$src"/*` — which, through the
destination symlink, expanded to the destination's own entries, so each file
was linked to itself. Result: `Too many levels of symbolic links`.

Fix: `link()` now resolves both sides with `readlink -f` and refuses a link
whose destination resolves to the source; `link_dir` iterates the resolved
source path and skips entries that point back into the destination. Empty
`readlink -f` results (broken links) are never compared as equal.

The repo itself was restored afterwards (`git checkout`) and contains only its
4 legitimate plugin symlinks.
## 8. vim removed; neovim is the only editor

vim was dropped from the setup entirely.

**What changed**

| Before | After |
|---|---|
| `vim`, `vim-gtk3` in the package manifest | `neovim` only (manifest now 55 packages) |
| `.vimrc`, `.gvimrc` symlinked to `$HOME` | deleted from the repo |
| `.vim/` (colors, after/syntax, spell, autoload/plug.vim) tracked | deleted from the repo |
| vim-plug fetched to `~/.vim/autoload/plug.vim` | fetched to `~/.local/share/nvim/site/autoload/plug.vim` |
| `alias v='vim'`, `alias vi='vim'` | both resolve to `nvim` |
| manual step "run `:PlugInstall` in vim" | "open `nvim` and run `:PlugInstall`" |

`EDITOR`/`VISUAL` already pointed at `nvim` in `zsh/.zshenv`, so nothing else
had to move.

**The important detail:** nvim reads plugins from `stdpath('data')`, i.e.
`~/.local/share/nvim/site/autoload/plug.vim`. Installing vim-plug into
`~/.vim/autoload` (as the README used to instruct) never worked for nvim —
it only ever served vim. The nvim config's `lua/plugins.lua` already
self-installs to the correct path on first start; the installer now matches it.

**Local cleanup performed:** the old `~/.vim/plugged` tree (78 plugins,
121 MB) was moved to `~/.dotfiles-backup/<timestamp>/vim-removal/plugged`,
the dangling `~/.vim/{after,autoload,colors,spell}` symlinks were removed, and
`~/.vim` itself was deleted. `~/.local/share/nvim/plugged` (64 plugins) was
left untouched.

**Verified:** `nvim --headless` starts with no errors against the linked
config; the installer reports 55/55 packages and 0 links to create.
## 9. CLI: `--help`, `--dry-run`, and Zinit ownership

### Help

`-h/--help` prints a structured reference: modes, options, profiles, package
policy, examples, environment variables, exit status. No arguments are needed
to discover behaviour.

### Dry run as a plan, not a log

`--dry-run` used to be a scatter of `[dry-run]` lines that only made sense if
you read the whole scrollback. It now journals every mutation into
`PLAN_ROWS` as `<phase>|<command>` and renders a grouped plan at the end:

```
════════════════ PLAN ════════════════
  Shell extras                                     2  action(s)
  XDG configs                                      1  action(s)
  Fonts                                            3  action(s)
  ──────────────────────────────────────
  12 action(s) would run.
  Nothing was changed.  Re-run without --dry-run to apply.
```

Mechanics:

- `run()` / `run_sh()` are the only ways to mutate. In dry-run they append to
  the journal and print `→ <command>`; otherwise they execute (and print
  `$ <command>` under `--verbose`).
- `info()` doubles as the phase marker, so groups match the real step order.
- `step()` prints a sub-line **without** starting a new phase — used for
  "installing N: …" so a dry run never says "Installing" when it installs
  nothing.
- `verb()` gates per-item detail behind `--verbose`, which `--dry-run` implies:
  `✔ pkg — already installed`, `⊘ pkg — provided by Zinit`.

`--quiet` suppresses progress but keeps warnings, errors and the summary, so
`--dry-run -q` is a compact plan-only view.

### Zinit owns its packages — enforced, not just documented

The previous version listed Zinit tooling in `ZINIT_PACKAGES` but only consulted
it when apt had *no candidate*. So `bat`, `fzf`, `jq`, `eza`, `gdu`, `direnv`
were still installed by apt even though `.zshrc` also installs them, leaving two
copies racing on `PATH`.

Fix: `ZINIT_PROVIDES` (name → binary) is checked at the top of `pkg_install`,
before `dpkg -s` and before `apt-cache`. Anything it names is skipped
unconditionally and reported as `provided by Zinit`. The duplicated names were
also removed from `SHELL_PACKAGES` / `FULL_PACKAGES` so the manifests have a
single source of truth.

Verified by unit test: `pkg_install "mixed" bat fzf gdu direnv jq libncursesw5-dev`
journals only `sudo apt-get install -y -qq libncursesw5-dev`.

**Known trade-off:** `rg` is Zinit-owned, but `bash/.bashrc` uses
`rg --files` as `FZF_DEFAULT_COMMAND`. Bash has no Zinit on `PATH`, so
fzf-in-bash needs `rg` to already exist. Documented in the README rather than
silently working around, since the alternative is re-introducing an apt copy.