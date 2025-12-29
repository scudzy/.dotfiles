# Start the timer
start="$(date +%s)"
# zmodload zsh/zprof
# zmodload -i zsh/complist

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Add your local paths to fpath BEFORE zicompinit runs
fpath=( ~/.dotfiles/zsh/functions $fpath )

# Set path
DOTFILES="${HOME}/.dotfiles"
ZDOTDIR="${DOTFILES}/zsh"
SNIPPETS="${HOME}/.dotfiles/snippets"

ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
    [ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
    [ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

# 1. Prevent Zinit from calling compinit itself
ZINIT[COMPINIT_ALREADY_CALLED]=1

# 2. Call compinit ONCE with a cache check (Fastest method)
autoload -Uz compinit
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.m-1) ]]; then
  compinit -C
else
  compinit
fi

# automatically remove duplicates from these arrays
typeset -U path cdpath fpath manpath

# Zinit block
zinit ice wait"0a" lucid
zinit snippet ~/.dotfiles/snippets/completion.zsh

zinit ice wait"0a" lucid; zinit snippet ~/.dotfiles/snippets/options.zsh
zinit ice wait"0a" lucid; zinit snippet ~/.dotfiles/snippets/history.zsh
zinit ice wait"0a" lucid; zinit snippet ~/.dotfiles/snippets/keybindings.zsh



# dircolors: Only run if it exists
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    export LS_COLORS="$LS_COLORS:ow=30;44:"

# Link LS_COLORS to completion (Do this AFTER dircolors)
    zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
    zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
fi
# Use your existing Zinit plugin for Man colors
# You already have OMZP::colored-man-pages in your Turbo block,
# so you don't need the LESS_TERMCAP exports here!

# zsh-autosuggestions
zinit ice wait"0" lucid atload"ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#999'; _zsh_autosuggest_start"
zinit load zsh-users/zsh-autosuggestions

### Added by Zinit's installer
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
    print -P "%F{33} %F{34}Installation successful.%f%b" || \
    print -P "%F{160} The clone has failed.%f%b"
fi
### End of Zinit's installer chunk

# Define the NVM directory (keep your XDG logic)
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"

# If you have a specific node version you want ready in the background:
zinit ice wait"1" lucid
zinit load lukechilds/zsh-nvm

# Disable Zinit's automatic completion management to save 1-2 seconds
# (We handle it manually with the single compinit call above)
zinit ice wait"0b" lucid atload"zinit cdreplay -q"

### load zinit modules
zinit light-mode for \
  zdharma-continuum/zinit-annex-{'readurl','bin-gem-node','patch-dl','rust'}

# --- Group 1: Essential UI (No wait, or very short wait) ---
zinit ice wait"0" lucid atinit"ZINIT[COMPINIT_OPTS]=-C; zicompinit; zicdreplay"
zinit light zdharma-continuum/fast-syntax-highlighting

zinit ice wait"0" lucid atload"_zsh_autosuggest_start"
zinit load zsh-users/zsh-completions

# --- Group 2: The "Heavy" OMZ Libraries ---
# Use '!' to force load in order
zinit wait"!" lucid for \
    OMZL::directories.zsh \
    OMZL::clipboard.zsh \
    OMZL::history.zsh \
    OMZL::git.zsh

# --- Group 3: The Plugins (Load these later, they aren't urgent) ---
zinit wait"1" lucid for \
    OMZP::sudo \
    OMZP::fzf \
    OMZP::colorize \
    OMZP::colored-man-pages \
    atload"unalias grv" OMZP::git \
    OMZP::python \
    OMZP::tmux

# Group 1: Fast binaries from GitHub Releases
# These load in the background (wait"2") to keep startup instant
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

### zsh-users/zsh-history-substring-search
# history substring searching
# only bind these keys once they're ready
bindkey -r "^[[A"
bindkey -r "^[[B"
zinit ice wait lucid \
  atload"
    zmodload zsh/terminfo
    bindkey '^[[A' history-substring-search-up
    bindkey '^[[B' history-substring-search-down"
zinit light zsh-users/zsh-history-substring-search

### zdharma-continuum/history-search-multi-word
zinit ice wait"1" lucid
zinit load zdharma-continuum/history-search-multi-word
zstyle ":history-search-multi-word" page-size "11"

### diff-so-fancy
zinit ice wait"1" lucid as"program" pick"bin/git-dsf"
zinit load zdharma-continuum/zsh-diff-so-fancy

### LS_COLORS Download the default profile
zinit ice lucid atclone"dircolors -b LS_COLORS > clrs.zsh" \
        atpull'%atclone' pick"clrs.zsh" nocompile'!' \
        atload'zstyle ":completion:*:default" list-colors "${(s.:.)LS_COLORS}";'
zinit light trapd00r/LS_COLORS

# direnv/direnv
# Load and unload environment variables depending on the current directory.
zi for \
    as"program" \
    atclone'./direnv hook zsh > zhook.zsh' \
    from"gh-r" \
    light-mode \
    mv"direnv* -> direnv" \
    src'zhook.zsh' \
  direnv/direnv
### eza-community/eza
zinit ice wait"1" lucid from"gh-r" as"program" \
        dl="https://raw.githubusercontent.com/eza-community/eza/refs/heads/main/completions/zsh/_eza" \
        multisrc''
zinit light eza-community/eza

# BurntSushi/ripgrep
# ripgrep recursively searches directories for a regex pattern while respecting your gitignore
zinit ice lucid as"command" from"gh-r" mv"ripgrep* -> rg" pick"rg/rg" \
        atclone"mv -vf rg/doc/rg.1 ${ZINIT[MAN_DIR]}/man1"
zinit light BurntSushi/ripgrep

# Fastfetch - Preset & Manpage management
zinit ice wait"3" lucid from"gh-r" as"command" bpick"*linux-amd64.tar.gz" \
    mv"fastfetch*/usr/bin/fastfetch -> fastfetch" \
    atclone'mv -vf fastfetch*/usr/share/man/man1/fastfetch.1 ${ZINIT[MAN_DIR]}/man1'
zinit light fastfetch-cli/fastfetch

### Install z.lua
zinit ice wait'!0'
zinit light skywind3000/z.lua

### b4b4r07/httpstat
zinit ice lucid wait as"program" pick"httpstat"
zinit light b4b4r07/httpstat

### dalance/procs
zinit for from'gh-r' sbin'**/procs -> procs' dalance/procs

### dbrgn/tealdeer
zinit ice lucid wait from"gh-r" as"command" pick"tldr" \
        mv"tealdeer* -> tldr" \
        dl="https://raw.githubusercontent.com/tealdeer-rs/tealdeer/refs/heads/main/completion/zsh_tealdeer -> _tldr"
zinit light tealdeer-rs/tealdeer



### gdu
zinit ice lucid wait from"gh-r" as"command" bpick"gdu_linux_amd64.tgz" mv"gdu_* -> gdu" \
       pick"gdu" dl="https://raw.githubusercontent.com/dundee/gdu/master/gdu.1" \
       atclone"mv -vf gdu.1 ${ZINIT[MAN_DIR]}/man1"
zinit light dundee/gdu

### dust
### A more intuitive version of du in rust
zinit ice lucid wait as"command" from"gh-r" mv"dust*x86_64*linux-gnu/dust -> dust" bpick"dust*x86_64*linux-gnu*" pick"dust" \
        dl="https://raw.githubusercontent.com/bootandy/dust/master/completions/_dust" \
        dl="https://raw.githubusercontent.com/bootandy/dust/master/man-page/dust.1" \
        atclone"
        mv -vf *.1 ${ZINIT[MAN_DIR]}/man1
        rm -rfv dust-*"
zinit light bootandy/dust

### Git-extras
zinit ice as"program" atclone"make PREFIX=$ZPFX install" \
        src"/home/scudzy/.local/share/zinit/plugins/tj---git-extras/etc/git-extras-completion.zsh"
zinit light tj/git-extras

### Chroma
zinit ice lucid wait as"program" from"gh-r" bpick"chroma-*-linux-amd64.*"
zinit light alecthomas/chroma

### fzf is a general-purpose command-line fuzzy finder.
### Load fzf, completion & key biindings
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
        mv -vf *.1 ${ZINIT[MAN_DIR]}/man1
        export FZF_BASE="$HOME/.local/share/zinit/plugins/junegunn---fzf"
        " \
      @junegunn/fzf

# Load all FZF variables, functions, and zstyles in the background
zinit ice wait"0b" lucid
zinit snippet ~/.dotfiles/snippets/fzf.zsh

# Slot 0b: Load after your core UI is ready
zinit ice wait"1" lucid
zinit light 'wfxr/forgit'

# Load the plugin
zinit ice wait"1" lucid has"fzf"
zinit light Aloxaf/fzf-tab

### oxipng
zinit ice wait"0b" from"gh-r" \
        mv"oxipng-*x86_64-unknown-linux-gnu* -> oxipng" \
        multisrc"~/.dotfiles/snippets/aliases.zsh ~/.dotfiles/snippets/xdg.zsh /etc/grc.zsh"
zinit light oxipng/oxipng

# dynamic aliases
for cmd in g++ gas head make ld ping6 tail traceroute6 $( ls /usr/share/grc/ ); do
        cmd="${cmd##*conf.}"
        type "${cmd}" >/dev/null 2>&1 && alias "${cmd}"="$( which grc ) --colour=auto ${cmd}"
done

### Checking Login v.s. Non-Login
if [[ -o Login ]]; then
    echo "Login"
    echo ""
    fastfetch -c ~/.config/fastfetch/archey.jsonc
    echo ""
else
    echo "Non-Login"
    echo ""
    fastfetch -c ~/.config/fastfetch/examples/8.jsonc
    echo ""
fi

########################## End of zinit line #############################

# xterm modes
if [ "$TERM" != "xterm-256color" ]; then
    export TERM=xterm-256color
fi

### bathelp
alias bathelp='bat --plain --language=help'
help() {
    "$@" --help 2>&1 | bathelp
}

### fzf pass ZSH
_fzf_complete_pass() {
  _fzf_complete +m -- "$@" < <(
    local prefix
    prefix="${PASSWORD_STORE_DIR:-$HOME/.password-store}"
    command find -L "$prefix" \
      -name "*.gpg" -type f | \
      sed -e "s#${prefix}/\{0,1\}##" -e 's#\.gpg##' -e 's#\\#\\\\#' | sort
  )
}

# Load powerline daemon and go-binary asynchronously
zinit ice wait"0" lucid atload'powerline-daemon -q'
zinit snippet /home/scudzy/.config/powerline/zsh/powerline.zsh

# Setup powerline-go in a hook
precmd_functions+=(powerline_precmd)
powerline_precmd() {
  PS1="$(/usr/bin/powerline-go -error $? -jobs ${${(%):%j}:-0})"
}
# end of powerline-status

### cargo
. "$HOME/.cargo/env"

# forgit
zinit ice wait lucid
zinit light 'wfxr/forgit'

# browserpass gnupg
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

### Function for pkglist
pkglist() { apt list "$1"* 2>/dev/null | rg -n --no-heading --color=always "${2:-^$1}"; }

# Disable Oh My Zsh's correction features
DISABLE_CORRECTION="true"

# 5. UI & PROMPT
zinit ice depth=1; zinit light romkatv/powerlevel10k
# To customize prompt, run `p10k configure` or edit ~/.dotfiles/zsh//.p10k.zsh.
[[ ! -f ~/.dotfiles/zsh//.p10k.zsh ]] || source ~/.dotfiles/zsh//.p10k.zsh

### direnv
eval "$(direnv hook zsh)"

# Slot 0a: Load local functions
zinit ice wait"0a" lucid as"null" \
    atinit'fpath+=( "$HOME/.dotfiles/zsh/functions" )' \
    atload'autoload -Uz $HOME/.dotfiles/zsh/functions/*(.:t)'
zinit snippet /dev/null

# Slot 0b: Your Completions
zinit ice wait"0b" lucid as"completion" \
    atload'zinit creinstall -q ~/.dotfiles/zsh/completions'
zinit snippet /dev/null

# Execution time
end="$(date +%s)"
total="$(( end - start ))"

# --- Ensure Startup Message Stays ---
# Flag to ensure the message only prints once per session
zsh_startup_message_shown=false

# Function to print the startup message
print_startup_message() {
    if ! $zsh_startup_message_shown; then
        # Ensure $total is defined earlier in your .zshrc if you want it to show a value.
        printf "\n\e[0;97m 💠 Loading your blazing 🚀 fast ⚡ shell in\e[39m \e[1;92;5m$total\e[0m 🔥 \e[0;97mseconds 👻 \e[0m\n\n\n"
        zsh_startup_message_shown=true
    fi
}
# Add the function to precmd_functions to run before the first prompt
# and subsequent prompts (but the flag will prevent re-printing)
precmd_functions+=(print_startup_message)
# --- End Startup Message ---

# Start zsh with a profiler
zmodload zsh/zprof
# (Add 'zprof' to the very bottom of your .zshrc, then restart and run 'zprof')
# Compile zcompdump in the background for next time
{
  if [[ -s "$HOME/.zcompdump" && (! -s "$HOME/.zcompdump.zwc" || "$HOME/.zcompdump" -nt "$HOME/.zcompdump.zwc") ]]; then
    zcompile "$HOME/.zcompdump"
  fi
} &!
