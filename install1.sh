#!/usr/bin/env bash
#
# install.sh — bootstrap this dotfiles repo into a fresh Debian/WSL2 install.
#
#   ./install.sh              interactive install
#   ./install.sh --dry-run    show every action, change nothing
#   ./install.sh --yes        non-interactive (profile: full)
#
# Design notes:
#   * The zsh config is NOT a symlinked shell.  zsh/.zshenv sets
#     ZDOTDIR="$DOTFILES/zsh", so ~/.zshrc and friends are read *in place*
#     from the clone.  The only thing that must exist in $HOME is the
#     ZDOTDIR pointer in ~/.zshenv (plus /etc/zsh/zshenv for non-login shells).
#   * Everything else (configs, fonts, scripts) is symlinked, never copied,
#     so `git pull` updates the live system.  Existing files are backed up.
#   * Nothing is ever overwritten silently; nothing is deleted.
#
set -euo pipefail

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
readonly DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
readonly REPO_URLS=(
  "https://gitlab.com/scudzy/dotfiles-wsl.git"
  "https://github.com/scudzy/dotfiles-wsl.git"
)
readonly BACKUP_ROOT="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
readonly MARKER_BEGIN="# >>> dotfiles install.sh >>>"
readonly MARKER_END="# <<< dotfiles install.sh <<<"

DRY_RUN=0
ASSUME_YES=0
PROFILE=""
SKIP_PKGS=0
NEED_LOCALE=0
__PROFILE_RANK=2

# Runtime state
BACKUP_MADE=0
declare -a LINKED=()       # successful links
declare -a SKIPPED=()      # pre-existing, left alone
declare -a FAILED=()       # errors
declare -a MANUAL=()       # follow-up steps

# ---------------------------------------------------------------------------
# Output helpers
# ---------------------------------------------------------------------------
if [[ -t 1 ]]; then
  C_RESET=$'\033[0m'; C_BOLD=$'\033[1m'; C_RED=$'\033[31m'
  C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'; C_BLUE=$'\033[34m'; C_DIM=$'\033[2m'
else
  C_RESET=""; C_BOLD=""; C_RED=""; C_GREEN=""; C_YELLOW=""; C_BLUE=""; C_DIM=""
fi

info()  { printf '%s\n' "${C_BLUE}==>${C_RESET} ${C_BOLD}$*${C_RESET}"; }
ok()    { printf '%s\n' "  ${C_GREEN}✔${C_RESET} $*"; }
warn()  { printf '%s\n' "  ${C_YELLOW}!${C_RESET} $*"; }
err()   { printf '%s\n' "  ${C_RED}✘${C_RESET} $*" >&2; }
note()  { printf '%s\n' "  ${C_DIM}$*${C_RESET}"; }
die()   { err "$*"; exit 1; }

# Run a command, honouring --dry-run.
run() {
  if (( DRY_RUN )); then
    printf '  %s[dry-run]%s %s\n' "$C_DIM" "$C_RESET" "$*"
    return 0
  fi
  "$@"
}

# Run a mutating shell snippet, honouring --dry-run.
run_sh() {
  if (( DRY_RUN )); then
    printf '  %s[dry-run]%s %s\n' "$C_DIM" "$C_RESET" "$1"
    return 0
  fi
  bash -c "$1"
}

confirm() {
  # confirm "question" [y|n]  — default second arg is n
  local prompt="$1" default="${2:-n}" reply hint
  if (( ASSUME_YES )); then return 0; fi
  if (( DRY_RUN )); then
    note "(dry-run) assuming '${default}': $prompt"
    [[ "$default" == "y" ]]; return
  fi
  if [[ ! -t 0 ]]; then return 0; fi   # piped/non-interactive: take the default
  hint="y/N"; [[ "$default" == "y" ]] && hint="Y/n"
  read -r -p "  ${C_BOLD}?${C_RESET} ${prompt} [${hint}] " reply || reply=""
  reply="${reply:-$default}"
  [[ "$reply" =~ ^[Yy] ]]
}

have() { command -v "$1" >/dev/null 2>&1; }

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
usage() {
  cat <<'EOF'
Usage: install.sh [OPTIONS]

Bootstrap the scudzy dotfiles into a Debian/WSL2 machine.

Options:
  -p, --profile NAME   Install profile: minimal | shell | full (default: ask)
  -y, --yes            Assume "yes" for every prompt (profile: full)
  -n, --dry-run        Print every action without changing anything
      --skip-packages  Do not install any OS packages
  -h, --help           Show this help and exit

Profiles:
  minimal   zsh entry points + DOTFILES, nothing else.
  shell     minimal + CLI tools, XDG configs, fonts, oh-my-posh.
  full      shell + vim/nvim, tmux, git, /etc tweaks.

Examples:
  ./install.sh --dry-run
  ./install.sh --profile shell --yes
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/scudzy/dotfiles/main/install.sh)"
EOF
}

while (( $# )); do
  case "$1" in
    -p|--profile)    PROFILE="${2:-}"; shift 2 ;;
    -y|--yes)        ASSUME_YES=1; shift ;;
    -n|--dry-run)    DRY_RUN=1; shift ;;
    --skip-packages) SKIP_PKGS=1; shift ;;
    -h|--help)       usage; exit 0 ;;
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

  have git || die "git is required first (sudo apt install git)."

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
# Step 2 — OS packages
# ---------------------------------------------------------------------------
pkg_install() {
  # pkg_install "label" pkg1 pkg2 ...
  local label="$1"; shift
  if (( SKIP_PKGS )); then note "skipping packages: $label (--skip-packages)"; return 0; fi

  local missing=() p
  for p in "$@"; do
    dpkg -s "$p" >/dev/null 2>&1 || missing+=("$p")
  done
  if (( ${#missing[@]} == 0 )); then ok "$label already installed"; return 0; fi

  info "Installing $label: ${missing[*]}"
  
  # Run update before installing
  run sudo apt-get update -qq || warn "apt-get update had issues"
  
  if ! run sudo apt-get install -y -qq "${missing[@]}"; then
    err "apt failed for: ${missing[*]}"
    FAILED+=("apt:$label")
  fi
  return 0
}

package_steps() {
  info "System packages"

  if (( NEED_LOCALE )); then
    pkg_install "locales" locales
    run sudo sed -i 's/^# *\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen || true
    run sudo locale-gen || warn "locale-gen failed"
  fi

  pkg_install "core shell tools" \
    zsh git curl wget ca-certificates unzip \
    bat ripgrep fd-find fzf jq less \
    pkg-config make perl

  if (( __PROFILE_RANK >= 2 )); then
    pkg_install "shell extras" \
      eza procs htop fastfetch tldr rclone pass gnupg fonts-terminus fonts-powerline
    pkg_install "build deps" \
      build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev \
      libsqlite3-dev libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev
  fi

  if (( __PROFILE_RANK >= 3 )); then
    pkg_install "editors"    vim neovim
    pkg_install "tmux"       tmux xsel grc
    pkg_install "cli extras" httpstat tree ncdu zip
    pkg_install "fonts"      fontconfig
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
    run mkdir -p "$BACKUP_ROOT"
    BACKUP_MADE=1
  fi
  run mkdir -p "$(dirname "$dest")"
  run mv "$target" "$dest"
  note "backed up $target -> $dest"
}

# ---------------------------------------------------------------------------
# Step 4 — symlink helpers
# ---------------------------------------------------------------------------
link() {
  local src="$1" dest="$2"
  [[ -e "$src" ]] || { warn "source missing, skipped: $src"; SKIPPED+=("$src"); return 0; }

  if [[ -L "$dest" ]]; then
    if [[ "$(readlink -f "$dest" 2>/dev/null)" == "$(readlink -f "$src")" ]]; then
      ok "already linked: $dest"; return 0
    fi
    note "replacing stale link $dest"
    run rm -f "$dest"
  elif [[ -e "$dest" ]]; then
    backup "$dest"
  fi

  run mkdir -p "$(dirname "$dest")"
  if run ln -sfn "$src" "$dest"; then
    ok "linked $dest -> $src"
    LINKED+=("$dest")
  else
    err "failed to link $dest"
    FAILED+=("link:$dest")
  fi
}

link_dir() {
  local src="$1" dest="$2" entry name
  [[ -d "$src" ]] || { warn "source dir missing, skipped: $src"; return 0; }
  run mkdir -p "$dest"
  
  # Enable nullglob temporarily
  local prev_shopt=$(shopt -p nullglob || true)
  shopt -s nullglob
  
  for entry in "$src"/* "$src"/.[!.]*; do
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
  
  # Restore previous shopt state
  $prev_shopt
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

  [[ -e "$target" || -L "$target" ]] && backup "$target"

  if (( DRY_RUN )); then
    note "[dry-run] write ZDOTDIR block to $target"
  else
    printf '%s\n' "$block" > "$target"
  fi
  ok "wrote $target"
  LINKED+=("$target")
}

install_bash_wiring() {
  info "bash wiring"
  link "$DOTFILES/bash/.bashrc"  "$HOME/.bashrc"
  link "$DOTFILES/bash/.profile" "$HOME/.profile"
  link "$DOTFILES/bash/.aliases" "$HOME/.aliases"   # .bashrc sources ~/.aliases
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

  if (( DRY_RUN )); then
    note "[dry-run] write $target"
  else
    printf '%s\n%s\n' \
      'export ZDOTDIR="${HOME}/.dotfiles/zsh"' \
      'export DOTFILES="${HOME}/.dotfiles"' \
      | sudo tee "$target" >/dev/null
  fi
  ok "wrote $target"
}

install_chsh() {
  local shell_path
  shell_path="$(command -v zsh || true)"
  
  # Fallbacks for standard Debian/WSL paths
  [[ -z "$shell_path" && -x "/usr/bin/zsh" ]] && shell_path="/usr/bin/zsh"
  [[ -z "$shell_path" && -x "/bin/zsh" ]] && shell_path="/bin/zsh"
  
  [[ -n "$shell_path" ]] || { warn "zsh not on PATH; cannot set login shell"; return; }

  if [[ "${SHELL:-}" == "$shell_path" ]]; then ok "login shell already zsh"; return; fi

  if ! grep -qx "$shell_path" /etc/shells 2>/dev/null; then
    run sudo sh -c "echo '$shell_path' >> /etc/shells"
  fi

  info "Setting login shell to $shell_path"
  if (( DRY_RUN )); then
    note "[dry-run] sudo chsh -s $shell_path $(id -un)"
  elif sudo chsh -s "$shell_path" "$(id -un)"; then
    ok "login shell set (takes effect on next login)"
  else
    warn "chsh failed; run manually"
    MANUAL+=("chsh -s $shell_path")
  fi
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
  clone_repo
  common_shell_steps
  install_etc_zshenv
  install_chsh
}

profile_shell() {
  info "Profile: shell"
  package_steps
  common_shell_steps
  install_etc_zshenv
  install_chsh

  info "XDG configs"
  # Credential-bearing dirs are natively skipped by link_dir's internal rules
  link_dir "$DOTFILES/.config" "$HOME/.config"

  info "Home dotfiles"
  link "$DOTFILES/.dircolors"    "$HOME/.dircolors"
  link "$DOTFILES/.editorconfig" "$HOME/.editorconfig"

  link "$DOTFILES/.gemrc"        "$HOME/.gemrc"
  link "$DOTFILES/.pythonrc"     "$HOME/.pythonrc"
  link "$DOTFILES/.tioconfig"    "$HOME/.tioconfig"

  info "Directories referenced by the zsh config"
  run mkdir -p "$HOME/.local/bin" "$HOME/.local/share" "$HOME/.cache"
  run mkdir -p "$HOME/.local/state/zsh"   # HISTFILE lives here

  info "fastfetch themes (greeting needs archey.jsonc)"
  link_dir "$DOTFILES/.config/fastfetch" "$HOME/.config/fastfetch"

  info "oh-my-posh"
  if have oh-my-posh; then
    ok "already installed"
  elif confirm "install oh-my-posh to ~/.local/bin?" y; then
    run_sh "curl -fsSL https://ohmyposh.dev/install.sh | bash -s -- -d '$HOME/.local/bin'" \
      || { err "oh-my-posh install failed"; FAILED+=("oh-my-posh"); }
  fi

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

  info "Editors"
  link "$DOTFILES/.vimrc"  "$HOME/.vimrc"
  link "$DOTFILES/.gvimrc" "$HOME/.gvimrc"
  link "$DOTFILES/.nanorc" "$HOME/.nanorc"
  link_dir "$DOTFILES/.vim" "$HOME/.vim"
  link_dir "$DOTFILES/.config/nvim" "$HOME/.config/nvim"

  if [[ -f "$HOME/.vim/autoload/plug.vim" ]]; then
    ok "vim-plug already installed"
  else
    info "vim-plug"
    run mkdir -p "$HOME/.vim/autoload"
    run_sh "curl -fLo '$HOME/.vim/autoload/plug.vim' --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim" \
      || { err "vim-plug download failed"; FAILED+=("vim-plug"); }
  fi
  MANUAL+=("Run :PlugInstall inside vim once")

  info "tmux"
  link "$DOTFILES/.tmux/.tmux.conf"       "$HOME/.tmux.conf"
  link "$DOTFILES/.tmux/.tmux.conf.local" "$HOME/.tmux.conf.local"
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
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
summary() {
  printf '\n%s\n' "${C_BOLD}${C_BLUE}──── Summary ────${C_RESET}"
  printf '  links created : %d\n' "${#LINKED[@]}"
  (( ${#SKIPPED[@]} )) && printf '  skipped       : %d (missing sources)\n' "${#SKIPPED[@]}"
  (( ${#FAILED[@]} ))  && printf '  %sfailures      : %d%s\n' "$C_RED" "${#FAILED[@]}" "$C_RESET"
  (( BACKUP_MADE ))    && printf '  backup        : %s\n' "$BACKUP_ROOT"

  if (( ${#MANUAL[@]} )); then
    printf '\n%s\n' "${C_BOLD}Manual follow-ups${C_RESET}"
    local m; for m in "${MANUAL[@]}"; do printf '  • %s\n' "$m"; done
  fi

  if (( ${#FAILED[@]} )); then
    printf '\n%s\n' "${C_RED}${C_BOLD}Completed with errors:${C_RESET}"
    local f; for f in "${FAILED[@]}"; do printf '  ✘ %s\n' "$f"; done
    return 1
  fi

  printf '\n%s\n' "${C_GREEN}${C_BOLD}Done.${C_RESET}"
  (( DRY_RUN )) && printf '%s\n' "${C_YELLOW}Dry run — nothing was changed.${C_RESET}"
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
  printf '  2) shell    — + CLI tools, XDG configs, fonts, oh-my-posh  %s(recommended)%s\n' "$C_DIM" "$C_RESET"
  printf '  3) full     — + vim/nvim, tmux, git, fonts\n'
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
  printf '%s\n' "${C_BOLD}dotfiles installer${C_RESET} ${C_DIM}(Debian/WSL2)${C_RESET}"
  (( DRY_RUN )) && printf '%s\n' "${C_YELLOW}DRY RUN — no changes will be made${C_RESET}"
  printf '  repo : %s\n' "$DOTFILES"

  preflight
  choose_profile
  printf '  profile : %s\n\n' "$PROFILE"

  case "$PROFILE" in
    minimal) profile_minimal ;;
    shell)   profile_shell ;;
    full)    profile_shell; profile_full ;;
  esac

  verify
  summary
}

main "$@"
