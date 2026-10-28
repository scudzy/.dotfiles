# ~/.zshrc - Interactive Zsh Configuration
zmodload zsh/datetime
zmodload zsh/stat
# Load Profiler (Uncomment for performance debugging)
# zmodload zsh/zprof

# Capture start time in milliseconds using pure Zsh float arithmetic
ZSH_START_TIME=$(( ${EPOCHREALTIME} * 1000 ))

# Paths & environment references
export DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
export ZDOTDIR="${ZDOTDIR:-$DOTFILES/zsh}"
export SNIPPETS="$DOTFILES/snippets"
export FZF_BASE="$HOME/.local/share/zinit/plugins/junegunn---fzf"
export PATH="$FZF_BASE:$PATH"
export _ZL_FZF="fzf"
export _ZL_MATCH_MODE=1
export _ZL_FZF_FLAG="--height 40% --reverse --border --ansi"

# Ensure custom functions and completions are added to fpath BEFORE compinit
typeset -gU fpath path cdpath manpath
fpath=( "$ZDOTDIR/functions" "$ZDOTDIR/completions" $fpath )

# Autoload custom functions from $ZDOTDIR/functions
autoload -Uz $ZDOTDIR/functions/*(.:t)

# Fast compinit initialization with 24-hour cache validation (pure Zsh, zero forks)
ZINIT_COMPINIT_SKIP=1
autoload -Uz compinit
local zcompdump="${ZDOTDIR:-$HOME}/.zcompdump"

if [[ -s "$zcompdump" && $(( EPOCHSECONDS - $(zstat +mtime "$zcompdump") )) -lt 86400 ]]; then
  compinit -C -d "$zcompdump"
else
  compinit -d "$zcompdump"
fi

# Background compile zcompdump if missing or outdated
if [[ -s "$zcompdump" && ! "$zcompdump.zwc" -nt "$zcompdump" ]]; then
  zcompile "$zcompdump" &!
fi

# Load Zinit Plugin Manager
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
    print -P "%F{33} %F{34}Installation successful.%f%b" || \
    print -P "%F{160} The clone has failed.%f%b"
fi
source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"

# --- Core UI & Highlighting Plugins ---
zinit ice wait'0a' lucid
zinit light zsh-users/zsh-autosuggestions

zinit ice wait'0b' lucid
zinit light zdharma-continuum/fast-syntax-highlighting

# Zinit annex modules
zinit light-mode for \
  zdharma-continuum/zinit-annex-{'readurl','bin-gem-node','patch-dl','rust'}

# Heavy plugins (Turbo Mode)
zinit wait'1' lucid for \
    zdharma-continuum/history-search-multi-word \
    zsh-users/zsh-history-substring-search

# diff-so-fancy
zinit ice wait"1" lucid as"program" pick"bin/git-dsf"
zinit load zdharma-continuum/zsh-diff-so-fancy

# Sourced snippets
zinit ice wait"0a" lucid; zinit snippet "$SNIPPETS/completion.zsh"
zinit ice wait"0a" lucid; zinit snippet "$SNIPPETS/options.zsh"
zinit ice wait"0a" lucid; zinit snippet "$SNIPPETS/history.zsh"
zinit ice wait"0a" lucid; zinit snippet "$SNIPPETS/keybindings.zsh"
zinit ice wait"0a" lucid; zinit snippet "$SNIPPETS/env.zsh"
zinit ice wait"0a" lucid; zinit snippet "$SNIPPETS/functions.zsh"

# dircolors: Only run if it exists
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    export LS_COLORS="$LS_COLORS:ow=30;44:"
    zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
    zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
fi

# Extra completions (Turbo Mode)
zinit ice wait'0' lucid blockf atpull'zinit creinstall -q .'
zinit light zsh-users/zsh-completions

# Oh My Zsh core libraries
zinit wait"!" lucid for \
    OMZL::directories.zsh \
    OMZL::clipboard.zsh \
    OMZL::history.zsh \
    OMZL::git.zsh

# Oh My Zsh plugins
zinit wait"1" lucid for \
    OMZP::sudo \
    OMZP::fzf \
    OMZP::colorize \
    OMZP::colored-man-pages \
    atload"unalias grv" OMZP::git \
    OMZP::python \
    OMZP::tmux

# Fast standalone binaries from GitHub Releases
zinit wait"2" lucid from"gh-r" as"null" for \
    sbin"**/fd"                @sharkdp/fd \
    sbin"**/vivid"             @sharkdp/vivid \
    sbin"**/bat"               @sharkdp/bat \
    sbin"**/h*e -> hyperfine"  @sharkdp/hyperfine \
    sbin"**/delta -> delta"    dandavison/delta \
    sbin"**/procs -> procs"    dalance/procs \
    sbin"**/glow"              charmbracelet/glow \
    sbin"**/gh"                cli/cli \
    sbin"* -> jq"              @jqlang/jq \
    sbin"**/grex"              pemistahl/grex \
    sbin"git-sizer"            @github/git-sizer

# LS_COLORS profile
zinit ice lucid atclone"dircolors -b LS_COLORS > clrs.zsh" \
        atpull'%atclone' pick"clrs.zsh" nocompile'!' \
        atload'zstyle ":completion:*:default" list-colors "${(s.:.)LS_COLORS}";'
zinit light trapd00r/LS_COLORS

# direnv
zi for \
    as"program" \
    atclone'./direnv hook zsh > zhook.zsh' \
    from"gh-r" \
    light-mode \
    mv"direnv* -> direnv" \
    src'zhook.zsh' \
  direnv/direnv

# eza
zinit ice wait"1" lucid from"gh-r" as"program" \
        dl="https://raw.githubusercontent.com/eza-community/eza/refs/heads/main/completions/zsh/_eza" \
        multisrc''
zinit light eza-community/eza

# ripgrep
zinit ice lucid as"command" from"gh-r" mv"ripgrep* -> rg" pick"rg/rg" \
        atclone"mv -vf rg/doc/rg.1 ${ZINIT[MAN_DIR]}/man1"
zinit light BurntSushi/ripgrep

# Fastfetch
zinit ice wait"3" lucid from"gh-r" as"command" bpick"*linux-amd64.tar.gz" \
    mv"fastfetch*/usr/bin/fastfetch -> fastfetch" \
    atclone'mv -vf fastfetch*/usr/share/man/man1/fastfetch.1 ${ZINIT[MAN_DIR]}/man1'
zinit light fastfetch-cli/fastfetch

# z.lua
zinit ice wait'!0' lucid
zinit light skywind3000/z.lua

# httpstat
zinit ice lucid wait as"program" pick"httpstat"
zinit light b4b4r07/httpstat

# zsh-vi-man
zinit light TunaCuma/zsh-vi-man

# tealdeer
zinit ice lucid wait from"gh-r" as"command" bpick"tealdeer-linux-x86_64-musl" pick"tldr" \
        mv"tealdeer* -> tldr" \
        dl="https://raw.githubusercontent.com/tealdeer-rs/tealdeer/refs/heads/main/completion/zsh_tealdeer -> _tldr"
zinit light tealdeer-rs/tealdeer

# gdu
zinit ice lucid wait from"gh-r" as"command" bpick"gdu_linux_amd64.tgz" mv"gdu_* -> gdu" \
       pick"gdu" dl="https://raw.githubusercontent.com/dundee/gdu/master/gdu.1" \
       atclone"mv -vf gdu.1 ${ZINIT[MAN_DIR]}/man1"
zinit light dundee/gdu

# dust
zinit ice lucid wait as"command" from"gh-r" mv"dust*x86_64*linux-gnu/dust -> dust" bpick"dust*x86_64*linux-gnu*" pick"dust" \
        dl="https://raw.githubusercontent.com/bootandy/dust/master/completions/_dust" \
        dl="https://raw.githubusercontent.com/bootandy/dust/master/man-page/dust.1" \
        atclone"
        mv -vf *.1 ${ZINIT[MAN_DIR]}/man1
        rm -rfv dust-*"
zinit light bootandy/dust

# Git-extras
zinit ice as"program" atclone"make PREFIX=$ZPFX install" \
        src"$HOME/.local/share/zinit/plugins/tj---git-extras/etc/git-extras-completion.zsh"
zinit light tj/git-extras

# Chroma
zinit ice lucid wait as"program" from"gh-r" bpick"chroma-*-linux-amd64.*"
zinit light alecthomas/chroma

# fzf binary, completion & key bindings
zinit for \
        as'command' \
        dl="https://raw.githubusercontent.com/junegunn/fzf/master/shell/key-bindings.zsh" \
        dl="https://raw.githubusercontent.com/junegunn/fzf/master/shell/completion.zsh -> _fzf" \
        dl="https://raw.githubusercontent.com/junegunn/fzf/master/man/man1/fzf.1" \
        dl="https://raw.githubusercontent.com/junegunn/fzf/master/man/man1/fzf-tmux.1" \
        from'gh-r' \
        null \
        pick'fzf' \
        src'key-bindings.zsh' \
        atclone"
        mv -vf *.1 ${ZINIT[MAN_DIR]}/man1" \
      @junegunn/fzf

# FZF-Tab
zinit ice wait'0' lucid
zinit light Aloxaf/fzf-tab

# Load all FZF variables, functions, and zstyles
zinit ice wait"0b" lucid
zinit snippet "$SNIPPETS/fzf.zsh"

# forgit
zinit ice wait"1" lucid atload'unalias grc gp gss'
zinit light 'wfxr/forgit'

# oxipng and snippets
zinit ice wait"0b" lucid from"gh-r" \
        mv"oxipng-*x86_64-unknown-linux-gnu* -> oxipng" \
        multisrc"~/.cargo/env $SNIPPETS/aliases.zsh $SNIPPETS/xdg.zsh /etc/grc.zsh"
zinit light oxipng/oxipng

# Dynamic aliases for grc
if (( $+commands[grc] )) && [[ -d /usr/share/grc ]]; then
    for conf in /usr/share/grc/conf.*; do
        cmd="${conf##*conf.}"
        (( $+commands[$cmd] )) && alias "$cmd"="grc --colour=auto $cmd"
    done
fi

# Terminal settings
if [ "$TERM" != "xterm-256color" ]; then
    export TERM=xterm-256color
fi

# Bathelp
alias bathelp='bat --plain --language=help'
help() {
    "$@" --help 2>&1 | bathelp
}

# Fzf pass helper
_fzf_complete_pass() {
  _fzf_complete +m -- "$@" < <(
    local prefix
    prefix="${PASSWORD_STORE_DIR:-$HOME/.password-store}"
    command find -L "$prefix" \
      -name "*.gpg" -type f | \
      sed -e "s#${prefix}/\{0,1\}##" -e 's#\.gpg##' -e 's#\\#\\\\#' | sort
  )
}

# Browserpass GnuPG Agent
PIDFOUND=$(pgrep gpg-agent)
if [ -n "$PIDFOUND" ]; then
    export GPG_AGENT_INFO="$HOME/.gnupg/S.gpg-agent:$PIDFOUND:1"
    export GPG_TTY=$(tty)
    export SSH_AUTH_SOCK="$HOME/.gnupg/S.gpg-agent.ssh"
    unset SSH_AGENT_PID
fi
PIDFOUND=$(pgrep dirmngr)
if [ -n "$PIDFOUND" ]; then
    export DIRMNGR_INFO="$HOME/.gnupg/S.dirmngr:$PIDFOUND:1"
fi
unset PIDFOUND

DISABLE_CORRECTION="true"

# Fastfetch greeting
if [[ -o Login ]]; then
    fastfetch -c ~/.config/fastfetch/archey.jsonc
else
    fastfetch -c ~/.config/fastfetch/examples/8.jsonc
fi

# Prompt: Oh-My-Posh
eval "$(oh-my-posh init zsh --config $HOME/.cache/oh-my-posh/themes/pure.omp.json)"

# translate-shell completion
compdef _gnu_generic trans

# Safe interactive .env sourcing
if [[ -f "$HOME/.env" ]]; then
    set -a; source "$HOME/.env"; set +a
fi

[[ -f "$HOME/.local/bin/env" ]] && . "$HOME/.local/bin/env"

# FZF completion trigger
export FZF_COMPLETION_TRIGGER='**'

# Calculate and display shell startup time
_print_shell_load_time() {
    local zsh_end_time=$(( ${EPOCHREALTIME} * 1000 ))
    local zsh_load_ms=$(( zsh_end_time - ZSH_START_TIME ))
    local zsh_load_sec=$(printf "%.3f" $(( zsh_load_ms / 1000.0 )))
    printf "\n\e[1m🚀 Shell loaded in \e[32m%s\e[0m \e[1mseconds\e[0m\n\n\n" "$zsh_load_sec"
    add-zsh-hook -d precmd _print_shell_load_time
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd _print_shell_load_time
export LD_LIBRARY_PATH=/usr/lib/wsl/lib:$LD_LIBRARY_PATH

# pnpm
export PNPM_HOME='/home/scudzy/.local/share/pnpm'
case ":$PATH:" in
  ":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac
# pnpm end
