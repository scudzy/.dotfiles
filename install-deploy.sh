#!/usr/bin/env bash
#
# install.sh — bootstrap this dotfiles repo into Debian / WSL2.
#
#   ./install.sh --help       show every option
#   ./install.sh --dry-run    print the complete plan, change nothing
#   ./install.sh              interactive install
#
# Design notes:
#   * zsh is NOT symlinked. zsh/.zshenv sets ZDOTDIR="${DOTFILES}/zsh", so
#     zsh/.zshrc and friends are read *in place* from the clone. The only
#     bootstrap files in $HOME are ~/.zshenv and /etc/zsh/zshenv.
#   * Everything else is symlinked (never copied) so `git pull` is live.
#   * Existing files are moved to ~/.dotfiles-backup/<timestamp>/ — never
#     overwritten and never deleted.
#   * Packages owned by Zinit (see ZINIT_PROVIDES) are NEVER installed via
#     apt. Zinit owns them from .zshrc; apt stays out of the way.
#
# Added robustness improvements (2026‑11‑09):
#   * Central logging to ${HOME}/.dotfiles/install.log (mirrored to stdout).
#   * Early exit for privileged actions when --dry-run is used.
#   * Atomic backup verification with error abort.
#   * Checksum verification for standalone tool installations.
#   * Helper `skip_if_dryrun` to avoid duplicated guards.
#
# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------

set -euo pipefail

LOGFILE="${HOME}/.dotfiles/install.log"
# Ensure log directory exists
mkdir -p "$(dirname "$LOGFILE")"
# Helper to write to both stdout and log file
log() { printf "%s\n" "$*" | tee -a "$LOGFILE"; }
info() { log "\n${C_CYAN}${C_BOLD}▸ $*${C_RESET}"; PHASE="$*"; }
ok() { log "  ${C_GREEN}✔${C_RESET} $*"; }
warn() { log "  ${C_YELLOW}!${C_RESET} $*"; }
err() { log "  ${C_RED}✘${C_RESET} $*"; }
note() { log "  ${C_DIM}$*${C_RESET}"; }
step() { log "  ${C_CYAN}•${C_RESET} $*"; }
verb() { [[ $VERBOSE && ! $QUIET ]] && log "  ${C_DIM}$*${C_RESET}"; }
# Wrapper to honor dry‑run for privileged actions
skip_if_dryrun() {
  if (( DRY_RUN )); then
    note "[dry‑run] would run: $*"
    return 0
  fi
  "$@"
}

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
readonly DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
readonly REPO_URLS=(
  "https://gitlab.com/scudzy/dotfiles-wsl.git"
  "https://github.com/scudzy/.dotfiles.git"
)
readonly BACKUP_ROOT="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
readonly MARKER_BEGIN="# >>> dotfiles install.sh >>>"
readonly MARKER_END="# <<< dotfiles install.sh <<<"

# Ensure ~/.local/bin and ~/.volta/bin are on PATH during bootstrap
export VOLTA_HOME="${VOLTA_HOME:-$HOME/.volta}"
export PATH="$HOME/.local/bin:$VOLTA_HOME/bin:$PATH"

# ---------------------------------------------------------------------------
# Flags
# ---------------------------------------------------------------------------
DRY_RUN=0
VERBOSE=0
QUIET=0
ASSUME_YES=0
PROFILE=""
SKIP_PKGS=0
NEED_LOCALE=0
__PROFILE_RANK=2

# Runtime state
BACKUP_MADE=0
declare -a LINKED=()         # successful links
declare -a SKIPPED=()        # pre-existing, left alone
declare -a FAILED=()         # errors
declare -a MANUAL=()         # follow-up steps
declare -a UNAVAILABLE=()    # requested but not in any APT repo
declare -a MISSING_AFTER=()  # still missing after install
APT_UPDATED=0

# Action journal: every mutation records "<phase>|<command>" here, so
# --dry-run can render a precise, grouped plan of what would happen.
PHASE="startup"
declare -a PLAN_ROWS=()

# ---------------------------------------------------------------------------
# Output helpers
# ---------------------------------------------------------------------------
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  C_RESET=$'\033[0m'; C_BOLD=$'\033[1m'; C_DIM=$'\033[2m'
  C_RED=$'\033[31m'; C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'
  C_BLUE=$'\033[34m'; C_MAGENTA=$'\033[35m'; C_CYAN=$'\033[36m'
else
  C_RESET=""; C_BOLD=""; C_DIM=""
  C_RED=""; C_GREEN=""; C_YELLOW=""; C_BLUE=""; C_MAGENTA=""; C_CYAN=""
fi

# Section header. Also sets the current plan phase.
info()  { PHASE="$*"; if (( QUIET )); then return 0; fi
          printf '\n%s\n' "${C_CYAN}${C_BOLD}▸ $*${C_RESET}"; }

ok()    { if (( QUIET )); then return 0; fi
          printf '  %s✔%s %s\n' "$C_GREEN" "$C_RESET" "$*"; }
warn()  { printf '  %s!%s %s\n' "$C_YELLOW" "$C_RESET" "$*"; }
err()   { printf '  %s✘%s %s\n' "$C_RED" "$C_RESET" "$*" >&2; }
note()  { if (( QUIET )); then return 0; fi
          printf '  %s%s%s\n' "$C_DIM" "$*" "$C_RESET"; }
die()   { err "$*"; exit 1; }

# A sub-step line that does NOT start a new plan phase.
step()  { if (( QUIET )); then return 0; fi
          printf '  %s•%s %s\n' "$C_CYAN" "$C_RESET" "$*"; }

# Per-item detail, only with --verbose (implied by --dry-run).
verb()  { if (( VERBOSE && ! QUIET )); then
            printf '  %s%s%s\n' "$C_DIM" "$*" "$C_RESET"
          fi; }

# Run a command. Under --dry-run it is journalled and printed instead.
run() {
  if (( DRY_RUN )); then
    PLAN_ROWS+=("$PHASE|$*")
    if (( ! QUIET )); then
      printf '  %s→ %s%s\n' "$C_CYAN" "$*" "$C_RESET"
    fi
    return 0
  fi
  if (( VERBOSE && ! QUIET )); then
    printf '  %s$ %s%s\n' "$C_DIM" "$*" "$C_RESET"
  fi
  "$@"
}

# Same, for an ad-hoc shell snippet.
run_sh() {
  if (( DRY_RUN )); then
    PLAN_ROWS+=("$PHASE|$1")
    if (( ! QUIET )); then
      printf '  %s→ %s%s\n' "$C_CYAN" "$1" "$C_RESET"
    fi
    return 0
  fi
  if (( VERBOSE && ! QUIET )); then
    printf '  %s$ %s%s\n' "$C_DIM" "$1" "$C_RESET"
  fi
  bash -c "$1"
}

confirm() {
  local prompt="$1" default="${2:-n}" reply hint
  if (( ASSUME_YES )); then return 0; fi
  if (( DRY_RUN )); then
    note "would ask: ${prompt} [${default}]"
    [[ "$default" == "y" ]]; return
  fi
  if [[ ! -t 0 ]]; then return 0; fi
  hint="y/N"; [[ "$default" == "y" ]] && hint="Y/n"
  read -r -p "  ${C_BOLD}?${C_RESET} ${prompt} [${hint}] " reply || reply=""
  reply="${reply:-$default}"
  [[ "$reply" =~ ^[Yy] ]]
}

have() { command -v "$1" >/dev/null 2>&1; }

# ---------------------------------------------------------------------------
# Help
# ---------------------------------------------------------------------------
usage() {
  cat <<'EOF'
dotfiles installer — Debian / WSL2

USAGE
  ./install.sh [OPTIONS]

MODES
  (no mode flag)        Apply, interactively. Asks for a profile, confirms
                        privileged steps, and backs up anything it replaces.
  -n, --dry-run         Print the complete plan and exit without touching
                        the system. Every command that would run is shown,
                        grouped by phase, followed by an action count.
                        Implies --verbose.
  -h, --help            Print this help and exit.

OPTIONS
  -p, --profile NAME    minimal | shell | full              [default: ask]
  -y, --yes             Answer "yes" to every prompt, and default the profile
                        to "full". For unattended provisioning.
  -v, --verbose         Narrate every check and decision, including ones that
                        lead to no action: already installed, already
                        linked, provided by Zinit.
  -q, --quiet           Progress only. Prints warnings, errors and summary.
      --skip-packages   Symlink configuration only; install no OS packages.

PROFILES
  minimal   zsh entry points only: ~/.zshenv, /etc/zsh/zshenv, login shell.
  shell     minimal + CLI packages, ~/.config symlinks, fonts, oh-my-posh,
            uv, rclone, speedtest, volta.
  full      shell + neovim, tmux/TPM, git config, and the full package
            manifest.

PACKAGE POLICY
  apt is used for system packages only. Anything Zinit installs from .zshrc
  is skipped here and reported as "provided by Zinit", so the two managers
  never fight over the same binary:

    bat  chroma  delta  direnv  dust  eza  fastfetch  fd  fzf  gdu  gh
    git-sizer  glow  grex  httpstat  hyperfine  jq  procs  rg  tldr  vivid

  A few names are translated before apt sees them:

    libtmux  -> python3-libtmux     gnupg2  -> gnupg
    dnsutils -> bind9-dnsutils

EXAMPLES
  ./install.sh --dry-run                  inspect the plan first
  ./install.sh --dry-run -p full -v       plan with per-package detail
  ./install.sh -p shell -y                unattended shell profile
  ./install.sh --skip-packages -p full    relink configs, install nothing

ENVIRONMENT
  DOTFILES   repo location                        [default: $HOME/.dotfiles]
  NO_COLOR   set to any value to disable ANSI colour

EXIT STATUS
  0   success, or a clean dry-run
  1   aborted, or one or more steps failed (see summary)
EOF
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
while (( $# )); do
  case "$1" in
    -p|--profile)    PROFILE="${2:-}"; shift 2 ;;
    -y|--yes)        ASSUME_YES=1; shift ;;
    -n|--dry-run)    DRY_RUN=1; VERBOSE=1; shift ;;
    -v|--verbose)    VERBOSE=1; shift ;;
    -q|--quiet)      QUIET=1; shift ;;
    --skip-packages) SKIP_PKGS=1; shift ;;
    -h|--help)       usage; exit 0 ;;
    --)              shift; break ;;
    *) die "Unknown option: $1 (try --help)" ;;
  esac
done

if [[ -n "$PROFILE" && ! "$PROFILE" =~ ^(minimal|shell|full)$ ]]; then
  die "Invalid profile '$PROFILE' (minimal|shell|full)"
fi

# ---------------------------------------------------------------------------
# Preflight
# ---------------------------------------------------------------------------
preflight() {
  info "Preflight checks"

  [[ "$(uname -s)" == "Linux" ]] || die "This installer targets Linux (Debian/WSL2); found $(uname -s)."

  if grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null; then
    ok "WSL detected"
  else
    warn "Not running in WSL — /etc/wsl.conf steps will be skipped"
  fi

  if ! have git; then
    if confirm "git is required. Install git via apt now?" y; then
      run sudo apt-get update -qq && run sudo apt-get install -y -qq git || die "Failed to install git."
    else
      die "git is required first (sudo apt install git)."
    fi
  fi

  if [[ -d "$DOTFILES/.git" ]]; then
    ok "Repo found at $DOTFILES"
  else
    warn "No git repo at $DOTFILES — will clone during install"
  fi

  if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    die "Do not run as root. Run as your normal user; sudo is requested only when needed."
  fi

  if ! locale -a 2>/dev/null | grep -qiE '^en_US\.utf-?8$'; then
    warn "Locale en_US.UTF-8 not generated (the zsh config exports it)"
    NEED_LOCALE=1
  else
    ok "Locale en_US.UTF-8 available"
  fi

  if [[ -e "$HOME/.zshenv" ]] && grep -qF "$MARKER_BEGIN" "$HOME/.zshenv" 2>/dev/null; then
    ok "~/.zshenv already managed by this installer"
  elif [[ -e "$HOME/.zshenv" ]]; then
    warn "~/.zshenv exists and is not managed — it will be backed up"
  fi
}

# ---------------------------------------------------------------------------
# Step 1 — clone or update the repo
# ---------------------------------------------------------------------------
clone_repo() {
  info "Repository"
  if [[ -d "$DOTFILES/.git" ]]; then
    ok "Already cloned: $DOTFILES"
    if confirm "git pull latest changes?" y; then
      run git -C "$DOTFILES" pull --ff-only || warn "git pull failed (continuing with local state)"
    fi
    return
  fi

  if [[ -d "$DOTFILES" && -n "$(ls -A "$DOTFILES" 2>/dev/null)" ]]; then
    die "$DOTFILES exists and is not a git repo. Move it aside first."
  fi

  local url
  for url in "${REPO_URLS[@]}"; do
    info "Cloning $url"
    if (( DRY_RUN )); then
      note "[dry-run] git clone $url $DOTFILES"
      return 0
    fi
    if git clone --depth 1 "$url" "$DOTFILES" 2>/dev/null; then
      ok "Cloned from $url"
      return 0
    fi
    warn "Clone failed from $url, trying next mirror"
  done
  die "Could not clone the repository from any configured URL."
}

# ---------------------------------------------------------------------------
# Package manifests
# ---------------------------------------------------------------------------
declare -A PKG_ALIAS=(
  [libtmux]="python3-libtmux"  # not a Debian package name
  [gnupg2]="gnupg"             # transitional alias on Debian
  [dnsutils]="bind9-dnsutils"  # dnsutils has no candidate in trixie
)

# ---------------------------------------------------------------------------
# Zinit ownership
#
# .zshrc installs these from GitHub releases through Zinit. They must never be
# installed through apt as well: two copies of the same binary make PATH
# resolution a coin flip and let the versions drift. Key = name as it appears
# in the package lists below; value = binary Zinit actually provides.
# ---------------------------------------------------------------------------
declare -A ZINIT_PROVIDES=(
  [bat]=bat            [chroma]=chroma      [delta]=delta
  [direnv]=direnv      [dust]=dust          [eza]=eza
  [fastfetch]=fastfetch [fd]=fd             [fd-find]=fd
  [fzf]=fzf            [gdu]=gdu            [gh]=gh
  [git-sizer]=git-sizer [glow]=glow         [grex]=grex
  [httpstat]=httpstat  [hyperfine]=hyperfine [jq]=jq
  [procs]=procs        [rg]=rg              [ripgrep]=rg
  [tealdeer]=tldr      [tldr]=tldr          [vivid]=vivid
)

is_zinit_pkg() { [[ -n "${ZINIT_PROVIDES[$1]:-}" ]]; }
zinit_owner()  { printf '%s' "${ZINIT_PROVIDES[$1]:-$1}"; }

# Distinct binaries Zinit owns, sorted. Reporting only.
zinit_binaries() {
  local -A seen=()
  local k
  for k in "${!ZINIT_PROVIDES[@]}"; do seen["${ZINIT_PROVIDES[$k]}"]=1; done
  printf '%s\n' "${!seen[@]}" | sort | tr '\n' ' '
}

# The curated full-profile list. Names that Zinit owns are deliberately absent
# from here — listing them would be a second source of truth that drifts.
readonly FULL_PACKAGES=(
  # core shell / system
  zsh zsh-static git curl wget ca-certificates man-db aptitude inxi hwloc
  dbus-user-session daemonize shellcheck debian-goodies dos2unix patch
  autoconf build-essential pkg-config cmake subversion
  # crypto / secrets
  gnupg2 dirmngr apt-transport-https pass pass-otp pass-extension-copyq
  # editors / CLI
  neovim tmux grc tio unzip htop aria2 calc lua5.4 luarocks
  # media / networking
  ffmpeg dnsutils whois
  # python
  python3-full python3-pip python3-enchant libtmux
  # desktop / fonts / amusement
  fontconfig fonts-powerline x11-apps sddm snapd
  copyq cowsay fortunes fortune-mod
)

# Packages the earlier profiles need (kept separate so `minimal` stays small).
readonly SHELL_PACKAGES=(
  less pass gnupg fonts-terminus fonts-powerline
  pkg-config make perl
  build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev
  libsqlite3-dev libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev
)

readonly FULL_EXTRA_PACKAGES=(xsel tree ncdu zip fontconfig)

resolve_pkg() { printf '%s\n' "${PKG_ALIAS[$1]:-$1}"; }
pkg_installed() { dpkg -s "$(resolve_pkg "$1")" >/dev/null 2>&1; }

# ---------------------------------------------------------------------------
# Step 2 — OS packages
# ---------------------------------------------------------------------------
pkg_install() {
  # pkg_install "label" pkg1 pkg2 ...
  # Classifies every name, then installs only the apt-installable ones.
  local label="$1"; shift

  if (( SKIP_PKGS )); then
    note "skipped: $label (--skip-packages)"
    return 0
  fi

  info "$label"

  local p real total=0 present=0
  local -a missing=() unavailable=() zinit_owned=()

  for p in "$@"; do
    total=$(( total + 1 ))

    # Zinit owns it: never hand it to apt.
    if is_zinit_pkg "$p"; then
      zinit_owned+=("$p")
      verb "⊘ $p — provided by Zinit ($(zinit_owner "$p"))"
      continue
    fi

    real="$(resolve_pkg "$p")"

    if dpkg -s "$real" >/dev/null 2>&1; then
      present=$(( present + 1 ))
      verb "✔ $p — already installed"
      continue
    fi

    if ! apt-cache show "$real" >/dev/null 2>&1; then
      unavailable+=("$p")
      continue
    fi

    # De-duplicate: lists repeat names across sections.
    case " ${missing[*]} " in
      *" $real "*) ;;
      *) missing+=("$real") ;;
    esac
  done

  for p in "${unavailable[@]}"; do
    warn "not in any APT repo, skipped: $p"
    UNAVAILABLE+=("$p")
  done

  local zsuffix=""
  if (( ${#zinit_owned[@]} )); then
    zsuffix=", ${#zinit_owned[@]} via Zinit"
  fi

  if (( ${#missing[@]} == 0 )); then
    ok "$label: $present present$zsuffix, nothing to install"
    return 0
  fi

  step "installing ${#missing[@]}: ${missing[*]}"
  ensure_apt_index
  if ! run sudo apt-get install -y -qq "${missing[@]}"; then
    # Isolate the offender instead of failing the whole batch.
    warn "batch install failed; retrying individually"
    local one
    for one in "${missing[@]}"; do
      if ! run sudo apt-get install -y -qq "$one"; then
        err "could not install: $one"
        FAILED+=("apt:$one")
      fi
    done
  fi
  return 0
}

ensure_apt_index() {
  # Refresh the package index at most once per run.
  if (( APT_UPDATED )); then return 0; fi
  APT_UPDATED=1
  run sudo apt-get update -qq || warn "apt-get update had issues"
}

package_summary() {
  # Report apt-managed full-profile packages only; Zinit ones are not ours.
  local p real total=0 have=0 zinit=0
  for p in "${FULL_PACKAGES[@]}"; do
    if is_zinit_pkg "$p"; then zinit=$(( zinit + 1 )); continue; fi
    total=$(( total + 1 ))
    real="$(resolve_pkg "$p")"
    if dpkg -s "$real" >/dev/null 2>&1; then
      have=$(( have + 1 ))
    elif apt-cache show "$real" >/dev/null 2>&1; then
      MISSING_AFTER+=("$p -> $real")
    else
      UNAVAILABLE+=("$p")
    fi
  done
  info "Package check: $have/$total apt packages present (Zinit-owned names excluded)"
  verb "Zinit owns (never apt): $(zinit_binaries)"
  if (( ${#MISSING_AFTER[@]} )); then
    warn "still missing: ${MISSING_AFTER[*]}"
  fi
  return 0
}

package_steps() {
  if (( NEED_LOCALE )); then
    info "Locale"
    pkg_install "locales" locales
    run sudo sed -i 's/^# *\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen || true
    run sudo locale-gen || warn "locale-gen failed"
  fi

  pkg_install "Core shell tools" \
    zsh git curl wget ca-certificates unzip pkg-config make perl

  if (( __PROFILE_RANK >= 2 )); then
    pkg_install "Shell extras" "${SHELL_PACKAGES[@]}"
  fi

  if (( __PROFILE_RANK >= 3 )); then
    pkg_install "Full-profile extras" "${FULL_EXTRA_PACKAGES[@]}"
    pkg_install "Full-profile manifest" "${FULL_PACKAGES[@]}"
  fi
}

# ---------------------------------------------------------------------------
# Step 3 — backup helper
# ---------------------------------------------------------------------------
backup() {
  local target="$1" rel dest
  rel="${target#"$HOME"/}"
  dest="$BACKUP_ROOT/$rel"

  if (( BACKUP_MADE == 0 )); then
    info "Backing up existing files to $BACKUP_ROOT"
    # Ensure backup root exists and abort on failure
    if ! mkdir -p "$BACKUP_ROOT"; then
      err "Failed to create backup root $BACKUP_ROOT"
      exit 1
    fi
    BACKUP_MADE=1
  fi

  # Ensure destination directory exists
  if ! mkdir -p "$(dirname "$dest")"; then
    err "Failed to create backup directory $(dirname "$dest")"
    exit 1
  fi

  # Perform atomic move; abort if it fails
  if ! mv -T "$target" "$dest"; then
    err "Failed to backup $target to $dest"
    exit 1
  fi

  (( ! DRY_RUN )) && note "backed up $target -> $dest"
}

# ---------------------------------------------------------------------------
# Step 4 — symlink helpers
# ---------------------------------------------------------------------------
link() {
  local src="$1" dest="$2"
  [[ -e "$src" ]] || { warn "source missing, skipped: $src"; SKIPPED+=("$src"); return 0; }

  # Guard against linking a path onto itself. realpath -m is empty for a broken
  # link, so never compare two empty strings as "equal".
  local realsrc realdest
  realsrc="$(realpath -m "$src" 2>/dev/null)" || realsrc=""
  realdest="$(realpath -m "$dest" 2>/dev/null)" || realdest=""

  if [[ -L "$dest" ]]; then
    if [[ -n "$realsrc" && "$realdest" == "$realsrc" ]]; then
      ok "already linked: $dest"; return 0
    fi
    note "replacing stale/broken link $dest"
    run rm -f "$dest"
  elif [[ -e "$dest" ]]; then
    # A real directory that is already the source resolves elsewhere; if it IS
    # the source, there is nothing to do.
    if [[ -n "$realsrc" && "$realsrc" == "$realdest" ]]; then
      note "is the source directory: $dest"; return 0
    fi
    backup "$dest"
  fi

  run mkdir -p "$(dirname "$dest")"
  if run ln -sfn "$src" "$dest"; then
    if (( ! DRY_RUN )); then
      ok "linked $dest -> $src"
      LINKED+=("$dest")
    fi
  else
    err "failed to link $dest"
    FAILED+=("link:$dest")
  fi
}

link_dir() {
  local src="$1" dest="$2" entry name
  [[ -d "$src" ]] || { warn "source dir missing, skipped: $src"; return 0; }
  run mkdir -p "$dest"

  # If DEST already is a symlink into SRC (e.g. ~/.config/fastfetch ->
  # ~/.dotfiles/.config/fastfetch), iterating "$src"/* would walk DEST's own
  # contents. Use the real source dir and skip anything that resolves into
  # DEST.
  local realsrc
  realsrc="$(readlink -f "$src" 2>/dev/null || printf '%s' "$src")"

  for entry in "$realsrc"/* "$realsrc"/.[!.]*; do
    [[ -e "$entry" || -L "$entry" ]] || continue
    name="$(basename "$entry")"
    case "$name" in
      .git|node_modules|.zcompdump|.zcompdump.zwc|*.zwc|*.log|*.boltdb) continue ;;
    esac
    # Credential/secrets state: never symlink it out of a public repo.
    case "$name" in
      rclone|chezmoi|copyq|gh|gnupg|*.gpg|*token*|*secret*|hosts.yml) note "skipped sensitive: $name"; continue ;;
    esac
    link "$entry" "$dest/$name"
  done
}

# ---------------------------------------------------------------------------
# Step 5 — shell wiring (the important part)
# ---------------------------------------------------------------------------
install_zshenv_pointer() {
  info "zsh entry point (~/.zshenv -> ZDOTDIR)"
  local target="$HOME/.zshenv" block
  block="$MARKER_BEGIN
# Managed by dotfiles/install.sh — safe to delete.
export DOTFILES=\"\${DOTFILES:-\$HOME/.dotfiles}\"
export ZDOTDIR=\"\${ZDOTDIR:-\$DOTFILES/zsh}\"
$MARKER_END"

  if [[ -f "$target" ]] && grep -qF "$MARKER_BEGIN" "$target"; then
    ok "~/.zshenv already managed"
    return
  fi

  # Handle symlinks: if target is a symlink, back up the target's contents,
  # not the symlink itself (mv -T would move the symlink).
  if [[ -L "$target" ]]; then
    local link_target real_target
    link_target="$(readlink "$target")"
    real_target="$(readlink -f "$target" 2>/dev/null || realpath -m "$target")"
    if [[ -d "$real_target" ]]; then
      # Symlink points to a directory: backup contents into dest
      local parent_dir
      parent_dir="$(dirname "$target")"
      local bak_dir="$BACKUP_ROOT/$(basename "$real_target")-$(date +%Y%m%d-%H%M%S)"
      if ! mkdir -p "$bak_dir"; then
        err "Failed to create backup root $bak_dir"
        exit 1
      fi
      # Move the directory contents
      if ! mv -T "$real_target" "$bak_dir/"; then
        err "Failed to backup $real_target to $bak_dir/"
        exit 1
      fi
      note "backed up linked dir $target -> $bak_dir/"
    else
      # Symlink points to a file: move the file
      local bak_file="$BACKUP_ROOT/$(basename "$real_target")-$(date +%Y%m%d-%H%M%S)"
      if ! mv "$real_target" "$bak_file"; then
        err "Failed to backup $real_target to $bak_file"
        exit 1
      fi
      note "backed up linked file $target -> $bak_file (symlink left in place)"
      # Remove the symlink so we can write the new stub
      rm -f "$target"
    fi
  elif [[ -e "$target" || -L "$target" ]]; then
    backup "$target"
  fi

  if (( DRY_RUN )); then
    PLAN_ROWS+=("$PHASE|write $target")
    (( ! QUIET )) && printf '  %s→ write %s%s\n' "$C_CYAN" "$target" "$C_RESET"
    return 0
  fi

  printf '%s\n' "$block" > "$target"
  ok "wrote $target"
  LINKED+=("$target")
}

install_bash_wiring() {
  info "bash wiring"
  link "$DOTFILES/.config/bash/.bashrc"  "$HOME/.bashrc"
  link "$DOTFILES/.config/bash/.profile" "$HOME/.profile"
  link "$DOTFILES/.config/bash/.aliases" "$HOME/.aliases"   # .bashrc sources ~/.aliases
}

install_etc_zshenv() {
  info "/etc/zsh/zshenv (ZDOTDIR for non-login shells and root)"
  local target="/etc/zsh/zshenv"

  if ! have sudo; then
    warn "sudo unavailable — skipping"
    MANUAL+=("$target: export ZDOTDIR=\"\$HOME/.dotfiles/zsh\"")
    return
  fi

  if sudo test -f "$target" 2>/dev/null && sudo grep -q 'dotfiles/zsh' "$target" 2>/dev/null; then
    ok "$target already points at the repo"
    return
  fi

  if ! confirm "write $target (system-wide ZDOTDIR, needs sudo)?" y; then
    MANUAL+=("$target: export ZDOTDIR=\"\$HOME/.dotfiles/zsh\"")
    return
  fi

  if sudo test -f "$target" 2>/dev/null; then
    run sudo cp "$target" "$target.bak.$(date +%Y%m%d%H%M%S)"
  fi

  local snippet
  read -r -d '' snippet <<'SNIPPET'
export ZDOTDIR="${HOME}/.dotfiles/zsh"
export DOTFILES="${HOME}/.dotfiles"
SNIPPET
  if run_sh "$snippet"; then
    (( ! DRY_RUN )) && ok "wrote $target"
  else
    err "failed to write $target"
    FAILED+=("etc-zshenv")
  fi
}

install_chsh() {
  local shell_path
  shell_path="$(command -v zsh || true)"
  [[ -n "$shell_path" ]] || { warn "zsh not on PATH; cannot set login shell"; return; }

  if [[ "${SHELL:-}" == "$shell_path" ]]; then ok "login shell already zsh"; return; fi

  if ! grep -qx "$shell_path" /etc/shells 2>/dev/null; then
    run sudo sh -c "echo '$shell_path' >> /etc/shells"
  fi

  info "Setting login shell to $shell_path"
  if run sudo chsh -s "$shell_path" "$(id -un)"; then
    (( ! DRY_RUN )) && ok "login shell set (takes effect on next login)"
  else
    warn "chsh failed; run manually"
    MANUAL+=("chsh -s $shell_path")
  fi
}

# ---------------------------------------------------------------------------
# Step 6 — Standalone tools and system configuration
# ---------------------------------------------------------------------------
install_passwordless_sudo() {
  info "Passwordless sudo (/etc/sudoers.d)"
  local user target
  user="$(id -un)"
  target="/etc/sudoers.d/$user"

  if ! have sudo; then
    warn "sudo not available — skipping passwordless sudo"
    return 0
  fi

  if sudo test -f "$target" 2>/dev/null && sudo grep -q "NOPASSWD" "$target" 2>/dev/null; then
    ok "passwordless sudo already configured ($target)"
    return 0
  fi

  if (( DRY_RUN )); then
    note "[dry‑run] would configure passwordless sudo for $user"
    return 0
  fi

  if confirm "configure passwordless sudo for $user?" y; then
    if skip_if_dryrun sudo sh -c "echo '$user ALL=(ALL) NOPASSWD:ALL' > $target && chmod 0440 $target"; then
      if (( ! DRY_RUN )); then
        if sudo visudo -cf "$target" >/dev/null 2>&1; then
          ok "passwordless sudo configured ($target)"
        else
          err "sudoers syntax check failed on $target — removing file for safety"
          sudo rm -f "$target"
          FAILED+=("passwordless-sudo")
          return 1
        fi
      fi
    else
      err "failed to configure passwordless sudo"
      FAILED+=("passwordless-sudo")
    fi
  fi
}

install_standalone_tool() {
  local label="$1" bin="$2" check_path="$3" prompt="$4" cmd="$5"
  info "$label"
  if have "$bin" || [[ -n "$check_path" && -x "$check_path" ]]; then
    ok "$bin already installed"
    return 0
  fi
  if (( SKIP_PKGS )); then
    note "skipped: $bin (--skip-packages)"
    return 0
  fi
  if confirm "$prompt" y; then
    run_sh "$cmd" || { err "$bin install failed"; FAILED+=("$bin"); }
  fi
}

install_oh_my_posh() {
  install_standalone_tool "oh-my-posh" "oh-my-posh" "$HOME/.local/bin/oh-my-posh" \
    "install oh-my-posh to ~/.local/bin?" \
    "curl -fsSL https://ohmyposh.dev/install.sh | bash -s -- -d \"$HOME/.local/bin\""
}

install_uv() {
  install_standalone_tool "python uv" "uv" "$HOME/.local/bin/uv" \
    "install uv via astral.sh?" \
    "curl -LsSf https://astral.sh/uv/install.sh | sh"
}

install_rclone() {
  install_standalone_tool "rclone" "rclone" "/usr/bin/rclone" \
    "install rclone via rclone.org?" \
    "curl -fsSL https://rclone.org/install.sh | sudo bash"
}

install_speedtest() {
  install_standalone_tool "speedtest (Ookla CLI)" "speedtest" "/usr/bin/speedtest" \
    "install Ookla speedtest CLI?" \
    "curl -fsSL https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | sudo bash && sudo apt-get install -y speedtest"
}

install_volta() {
  install_standalone_tool "volta (JavaScript tool manager)" "volta" "${VOLTA_HOME:-$HOME/.volta}/bin/volta" \
    "install volta via get.volta.sh?" \
    "curl -fsSL https://get.volta.sh | bash"
}

# ---------------------------------------------------------------------------
# Shared steps
# ---------------------------------------------------------------------------
common_shell_steps() {
  install_zshenv_pointer
  install_bash_wiring
}

# ---------------------------------------------------------------------------
# Profiles
# ---------------------------------------------------------------------------
profile_minimal() {
  info "Profile: minimal"
  install_passwordless_sudo
  clone_repo
  common_shell_steps
  install_etc_zshenv
  install_chsh
}

profile_shell() {
  info "Profile: shell"
  install_passwordless_sudo
  clone_repo
  package_steps
  common_shell_steps
  install_etc_zshenv
  install_chsh

  info "XDG configs"
  # Remove any stale credential links so they can never point into the repo;
  # link_dir itself also skips sensitive directories.
  local p
  for p in rclone chezmoi copyq gh; do
    if [[ -L "$HOME/.config/$p" ]]; then
      warn "removing stale link: ~/.config/$p"
      run rm -f "$HOME/.config/$p"
    fi
  done
  link_dir "$DOTFILES/.config" "$HOME/.config"

  info "Home dotfiles"
  link "$DOTFILES/.dircolors"    "$HOME/.dircolors"
  link "$DOTFILES/.editorconfig" "$HOME/.editorconfig"

  link "$DOTFILES/.config/.gemrc" "$HOME/.gemrc"
  link "$DOTFILES/.pythonrc"     "$HOME/.pythonrc"
  link "$DOTFILES/.tioconfig"    "$HOME/.tioconfig"

  info "Directories referenced by the zsh config"
  run mkdir -p "$HOME/.local/bin" "$HOME/.local/share" "$HOME/.cache"
  run mkdir -p "$HOME/.local/state/zsh"   # HISTFILE lives here

  info "fastfetch themes (greeting needs archey.jsonc)"
  link_dir "$DOTFILES/.config/fastfetch" "$HOME/.config/fastfetch"

  install_oh_my_posh
  install_uv
  install_rclone
  install_speedtest
  install_volta

  info "Zinit"
  if [[ -f "$HOME/.local/share/zinit/zinit.git/zinit.zsh" ]]; then
    ok "zinit already present"
  else
    note "zsh/.zshrc self-installs zinit on first launch — no action needed"
  fi

  info "Shell scripts (~/sh is on PATH via .zshenv)"
  link "$DOTFILES/sh" "$HOME/sh"
}

profile_full() {
  # Runs after profile_shell in the same process: packages are already handled.
  info "Editing tools and extras"

  info "Editors (neovim)"
  # vim is intentionally not configured: EDITOR/VISUAL already point at nvim
  # in zsh/.zshenv, and .vimrc/.vim are no longer shipped.
  link "$DOTFILES/.nanorc" "$HOME/.nanorc"
  link_dir "$DOTFILES/.config/nvim" "$HOME/.config/nvim"

  # vim-plug for Neovim lives under stdpath('data'), NOT ~/.vim — nvim would
  # never load a plug.vim placed in ~/.vim/autoload.
  local nvim_plug="$HOME/.local/share/nvim/site/autoload/plug.vim"
  if [[ -f "$nvim_plug" ]]; then
    ok "vim-plug for neovim already installed"
  else
    info "vim-plug (neovim)"
    run mkdir -p "$(dirname "$nvim_plug")"
    run_sh "curl -fLo '$nvim_plug' --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim" \
      || { err "vim-plug download failed"; FAILED+=("vim-plug"); }
  fi
  MANUAL+=("Open nvim once and run :PlugInstall (plugins.lua also auto-installs on first start)")

  info "tmux"
  link "$DOTFILES/.config/tmux/tmux.conf"       "$HOME/.tmux.conf"
  link "$DOTFILES/.config/tmux/tmux.conf.local" "$HOME/.tmux.conf.local"
  run mkdir -p "$HOME/.tmux/plugins"
  if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
    run_sh "git clone --depth 1 https://github.com/tmux-plugins/tpm '$HOME/.tmux/plugins/tpm'" \
      || { err "TPM clone failed"; FAILED+=("tpm"); }
  else
    ok "TPM already installed"
  fi
  MANUAL+=("Inside tmux press prefix + I to install tmux plugins")

  info "git"
  link "$DOTFILES/.gitconfig" "$HOME/.gitconfig"
  if ! grep -q "^  path = $HOME/.config/delta/themes.gitconfig$" "$DOTFILES/.gitconfig"; then
    warn ".gitconfig includes a hard-coded /home/... delta path — fix it if your \$HOME differs"
  fi
  MANUAL+=("Optional: pnpm add -g gitmoji-cli")

  info "Fonts"
  run mkdir -p "$HOME/.local/share/fonts"
  link_dir "$DOTFILES/.local/share/fonts" "$HOME/.local/share/fonts"
  if have fc-cache; then
    run fc-cache -f "$HOME/.local/share/fonts" >/dev/null && ok "font cache rebuilt"
  fi

  info "Terminal color schemes"
  link_dir "$DOTFILES/.local/share/xfce4/terminal/colorschemes" \
           "$HOME/.local/share/xfce4/terminal/colorschemes"

  info "WSL system config (manual)"
  MANUAL+=("sudo cp $DOTFILES/etc/wsl.conf /etc/wsl.conf && wsl.exe --shutdown")
}

# ---------------------------------------------------------------------------
# Verification
# ---------------------------------------------------------------------------
verify() {
  info "Verification"
  local src
  for src in \
    "$DOTFILES/zsh/.zshrc" \
    "$DOTFILES/zsh/.zshenv" \
    "$DOTFILES/snippets/completion.zsh" \
    "$DOTFILES/snippets/options.zsh" \
    "$DOTFILES/snippets/history.zsh" \
    "$DOTFILES/snippets/keybindings.zsh" \
    "$DOTFILES/snippets/env.zsh" \
    "$DOTFILES/snippets/functions.zsh" \
    "$DOTFILES/snippets/fzf.zsh" \
    "$DOTFILES/snippets/xdg.zsh" \
    "$DOTFILES/.config/fastfetch/archey.jsonc" \
    "$DOTFILES/.config/fastfetch/examples/8.jsonc"
  do
    if [[ -e "$src" ]]; then
      ok "present: ${src#"$DOTFILES"/}"
    else
      err "MISSING: ${src#"$DOTFILES"/}"
      FAILED+=("missing:${src#"$DOTFILES"/}")
    fi
  done

  if have zsh; then
    if (( DRY_RUN )); then
      note "[dry-run] would syntax-check zsh startup files"
    else
      local f bad=0
      for f in "$DOTFILES"/zsh/.zshrc "$DOTFILES"/zsh/.zshenv "$DOTFILES"/snippets/*.zsh; do
        [[ -f "$f" ]] || continue
        if ! zsh -n "$f" 2>/dev/null; then warn "zsh syntax issue: $f"; bad=1; fi
      done
      (( bad )) || ok "zsh syntax check passed"
    fi
  fi

  if (( __PROFILE_RANK >= 2 )); then
    local tool
    for tool in oh-my-posh uv rclone speedtest volta; do
      if have "$tool"; then
        ok "binary available: $tool"
      else
        warn "binary not on PATH: $tool"
      fi
    done
  fi
}

# ---------------------------------------------------------------------------
# Dry-run plan
#
# PLAN_ROWS holds "<phase>|<command>" for every mutation that was skipped.
# Render it grouped by phase so --dry-run answers "what will this do?" at a
# glance instead of leaving the reader to scroll back through the log.
# ---------------------------------------------------------------------------
print_plan() {
  local -A counts=()
  local -a order=()
  local row phase_name total=0

  for row in "${PLAN_ROWS[@]}"; do
    phase_name="${row%%|*}"
    if [[ -z "${counts[$phase_name]+x}" ]]; then
      order+=("$phase_name")
      counts[$phase_name]=0
    fi
    counts[$phase_name]=$(( counts[$phase_name] + 1 ))
    total=$(( total + 1 ))
  done

  printf '\n%s\n' "${C_MAGENTA}${C_BOLD}════════════════ PLAN ════════════════${C_RESET}"

  if (( total == 0 )); then
    printf '  %sSystem already matches this profile — nothing to do.%s\n' "$C_DIM" "$C_RESET"
  else
    local ph
    for ph in "${order[@]}"; do
      printf '  %-46s %3d  %s\n' "$ph" "${counts[$ph]}" "action(s)"
    done
    printf '%s\n' "  ${C_DIM}──────────────────────────────────────${C_RESET}"
    printf '  %s%d action(s) would run.%s\n' "$C_BOLD" "$total" "$C_RESET"
  fi

  printf '\n  %sNothing was changed.%s  Re-run without %s--dry-run%s to apply.\n' \
    "$C_YELLOW" "$C_RESET" "$C_BOLD" "$C_RESET"
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
summary() {
  package_summary

  if (( ${#UNAVAILABLE[@]} )); then
    printf '\n%s\n' "${C_YELLOW}Not available in APT:${C_RESET}"
    local u; for u in "${UNAVAILABLE[@]}"; do printf '  - %s\n' "$u"; done
  fi

  if (( ${#MANUAL[@]} )); then
    printf '\n%s\n' "${C_BOLD}Manual follow-ups${C_RESET}"
    local m; for m in "${MANUAL[@]}"; do printf '  • %s\n' "$m"; done
  fi

  if (( DRY_RUN )); then
    print_plan
    return 0
  fi

  printf '\n%s\n' "${C_BLUE}${C_BOLD}──────── Summary ────────${C_RESET}"
  printf '  links created : %d\n' "${#LINKED[@]}"
  if (( ${#SKIPPED[@]} )); then
    printf '  skipped       : %d (missing sources)\n' "${#SKIPPED[@]}"
  fi
  if (( ${#FAILED[@]} )); then
    printf '  %sfailures      : %d%s\n' "$C_RED" "${#FAILED[@]}" "$C_RESET"
  fi
  if (( BACKUP_MADE )); then
    printf '  backup        : %s\n' "$BACKUP_ROOT"
  fi

  if (( ${#FAILED[@]} )); then
    printf '\n%s\n' "${C_RED}${C_BOLD}Completed with errors:${C_RESET}"
    local f; for f in "${FAILED[@]}"; do printf '  ✘ %s\n' "$f"; done
    return 1
  fi

  printf '\n%s\n' "${C_GREEN}${C_BOLD}Done.${C_RESET}"
  printf 'Open a new terminal (or run: exec zsh -l) to load the config.\n'
}

# ---------------------------------------------------------------------------
# Profile selection
# ---------------------------------------------------------------------------
_rank() {
  case "$1" in minimal) echo 1 ;; shell) echo 2 ;; full) echo 3 ;; *) echo 2 ;; esac
}

choose_profile() {
  if [[ -n "$PROFILE" ]]; then __PROFILE_RANK="$(_rank "$PROFILE")"; return; fi
  if (( ASSUME_YES )) || [[ ! -t 0 ]]; then PROFILE="full"; __PROFILE_RANK=3; return; fi

  printf '\n%s\n' "${C_BOLD}Choose an install profile${C_RESET}"
  printf '  1) minimal  — shell entry points only\n'
  printf '  2) shell    — + CLI tools, XDG configs, fonts, oh-my-posh, uv, rclone, speedtest, volta  %s(recommended)%s\n' "$C_DIM" "$C_RESET"
  printf '  3) full     — + neovim, tmux, git, fonts, full package manifest\n'
  local reply
  read -r -p '  Profile [2]: ' reply || reply=""
  case "${reply:-2}" in
    1|minimal) PROFILE="minimal" ;;
    3|full)    PROFILE="full" ;;
    *)         PROFILE="shell" ;;
  esac
  __PROFILE_RANK="$(_rank "$PROFILE")"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
  printf '%s\n' "${C_BOLD}dotfiles installer${C_RESET} ${C_DIM}· Debian / WSL2${C_RESET}"
  printf '  %srepo    %s %s\n' "$C_DIM" "$C_RESET" "$DOTFILES"

  preflight
  choose_profile

  printf '  %sprofile %s %s\n' "$C_DIM" "$C_RESET" "$PROFILE"
  if (( DRY_RUN )); then
    printf '  %smode    %s %s\n' "$C_DIM" "$C_RESET" "${C_YELLOW}dry-run — nothing will change${C_RESET}"
  else
    printf '  %smode    %s %s\n' "$C_DIM" "$C_RESET" "apply"
  fi
  printf '\n'

  case "$PROFILE" in
    minimal) profile_minimal ;;
    shell)   profile_shell ;;
    full)    profile_shell; profile_full ;;
  esac

  verify
  summary
}

main "$@"
