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

# # ensure compinit recognizes zinit's changes
# autoload -Uz _zinit
# (( ${+_comps} )) && _comps[zinit]=_zinit

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

# # Load your local custom configs in one go
# # wait"0a" ensures these load immediately after the shell starts
# zinit ice wait"0a" lucid nocompile'!'
# zinit snippet ~/.dotfiles/snippets/aliases.zsh

# zinit ice wait"0a" lucid nocompile'!'
# zinit snippet ~/.dotfiles/snippets/xdg.zsh

# [[ -f /etc/grc.zsh ]] && source /etc/grc.zsh

# Zinit block
zinit ice wait"0a" lucid
zinit snippet ~/.dotfiles/snippets/completion.zsh

zinit ice wait"0a" lucid; zinit snippet ~/.dotfiles/snippets/options.zsh
zinit ice wait"0a" lucid; zinit snippet ~/.dotfiles/snippets/history.zsh
zinit ice wait"0a" lucid; zinit snippet ~/.dotfiles/snippets/keybindings.zsh

# # Load behavioral settings and history logic first
# zinit ice wait"0a" lucid
# zinit snippet ~/.dotfiles/snippets/options.zsh

# zinit ice wait"0a" lucid
# zinit snippet ~/.dotfiles/snippets/history.zsh

# zinit ice wait"0b" lucid
# zinit snippet ~/.dotfiles/snippets/keybindings.zsh

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

# enable auto-suggestions based on the history
# if [ -f $HOME/.local/share/zinit/plugins/zsh-users---zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
#     . $HOME/.local/share/zinit/plugins/zsh-users---zsh-autosuggestions/zsh-autosuggestions.zsh
#     # change suggestion color
#     ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#999'
# fi

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

# ### nvm
# export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
# [[ -s "$NVM_DIR/nvm.sh" ]] && \. "$NVM_DIR/nvm.sh" # This loads nvm

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

# # declare-zsh
# zinit ice wait lucid
# zinit load zdharma-continuum/declare-zsh

# # async support
# zinit ice wait lucid \
#       atload"async_init" \
#       src"async.zsh"
# zinit light mafredri/zsh-async

# # zsh better npm completion
# zinit ice wait lucid src"zsh-better-npm-completion.plugin.zsh"
# zinit load lukechilds/zsh-better-npm-completion

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

# ### sharkdp/fd
# ### A simple, fast, and user-friendly alternative to 'find'.
# zinit ice lucid wait"1" as"command" from"gh-r" mv"fd* -> fd" pick"fd/fd" \
#     atclone"
#         mv -vf fd*/autocomplete/_fd _fd
#         mv -vf fd*/fd.1 ${ZINIT[MAN_DIR]}/man1"
# zinit light sharkdp/fd

# ### vivid
# zinit ice lucid wait"1" as"command" from"gh-r" mv"vivid* -> vivid" pick"vivid/vivid" \
#     atload'export LS_COLORS="$(vivid generate snazzy)"'
# zinit light sharkdp/vivid

# ### sharkdp/bat
# ### A cat(1) clone with syntax highlighting and Git integration.
# zinit ice lucid wait"1" as"command" from"gh-r" mv"bat* -> bat" pick"bat/bat" \
#     atclone"
#         mv -vf bat*/autocomplete/bat.zsh _bat
#         mv -vf bat*/bat.1 ${ZINIT[MAN_DIR]}/man1"
# zinit light sharkdp/bat

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

# git-sizer
# # Compute various size metrics for a Git repository, flagging those that might cause problems.
# zi for \
#     from'gh-r'      \
#     sbin'git-sizer' \
#   @github/git-sizer

### eza-community/eza
zinit ice wait"1" lucid from"gh-r" as"program" \
        dl="https://raw.githubusercontent.com/eza-community/eza/refs/heads/main/completions/zsh/_eza" \
        multisrc''
zinit light eza-community/eza

# ### All of the above using the for-syntax and also z-a-bin-gem-node annex
# zinit wait"1" lucid from"gh-r" as"null" for \
#         sbin"**/fd"            @sharkdp/fd \
#         sbin"**/vivid"         @sharkdp/vivid \
#         sbin"**/bat"           @sharkdp/bat

# # hyperfine
# # A command-line benchmarking tool.
# zi for \
#         from'gh-r' \
#         sbin'**/h*e -> hyperfine' \
#         @sharkdp/hyperfine

# BurntSushi/ripgrep
# ripgrep recursively searches directories for a regex pattern while respecting your gitignore
zinit ice lucid as"command" from"gh-r" mv"ripgrep* -> rg" pick"rg/rg" \
        atclone"mv -vf rg/doc/rg.1 ${ZINIT[MAN_DIR]}/man1"
zinit light BurntSushi/ripgrep

# # delta
# # A syntax-highlighting pager for git, diff, and grep output.
# zi for \
#         from'gh-r' \
#         sbin'**/delta -> delta' \
#         dandavison/delta

# ### fastfetch
# zinit ice wait from"gh-r" as"command" bpick"fastfetch-linux-amd64.tar.gz" \
#         mv"fastfetch*/usr/bin/fastfetch -> fastfetch" pick"fastfetch*/fastfetch" \
#         atclone"
#         mv -vf fastfetch*/usr/share/man/man1/fastfetch.1 ${ZINIT[MAN_DIR]}/man1
#         cp -rvf fastfetch*/usr/share/fastfetch/presets ~/.config/fastfetch
#         ln -sfv /home/scudzy/.local/share/zinit/plugins/fastfetch-cli---fastfetch/fastfetch ~/.local/bin/fastfetch"
# zinit light fastfetch-cli/fastfetch

# # Direnv - Custom hook generation
# zinit ice wait"2" lucid from"gh-r" as"program" mv"direnv* -> direnv" \
#     atclone'./direnv hook zsh > zhook.zsh' atpull'%atclone' src"zhook.zsh"
# zinit light direnv/direnv

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

# ### charmbracelet/glow
# ### Glow is a terminal-based markdown reader designed from the ground up to bring out the beauty—and power—of the CLI.
# zinit for from'gh-r' sbin'**/glow' charmbracelet/glow

### Github CLI
# ### GitHub’s official command-line tool
# zinit for from'gh-r' sbin'**/gh' cli/cli

# ### jq
# ### jq is a lightweight and flexible command-line JSON processor.
# zinit for from'gh-r' sbin'* -> jq' nocompile @jqlang/jq

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

# ### grex
# ### A command-line tool and library for generating regular expressions from user-provided test cases.
# zinit ice lucid wait as"program" from"gh-r" bpick"grex-*-x86_64-unknown-linux-musl.tar.gz" pick'grex'
# zinit light pemistahl/grex

# # Utilize Turbo and initialize the completion system
# zinit id-as=system-completions wait as=completion lucid \
#     atclone='print Installing system completions...; \
#       mkdir -p $ZPFX/funs; \
#       command cp -rf /usr/share/zsh/functions/^_* $ZPFX/funs; \
#       zinit creinstall -q /usr/share/zsh/functions' \
#     atload='fpath=( ${(u)fpath[@]:#/use/share/zsh/*} ); \
#       fpath+=( $ZPFX/funs )' \
#     atpull="%atclone" for \
#          zdharma-continuum/null

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

### tab completions via fzf-tab
# zinit ice wait"1" lucid \
#   has"fzf" \
#   atload"
#         zstyle ':completion:*' verbose yes
#         zstyle ':completion:*' list-colors \${(s.:.)LS_COLORS}
#         zstyle ':completion:*:descriptions' format '[%d]'
#         zstyle ':completion::complete:*:*:files' ignored-patterns '.DS_Store' 'Icon?' '.Trash'
#         zstyle ':completion::complete:*:*:globbed-files' ignored-patterns '.DS_Store' 'Icon?' '.Trash'
#         zstyle ':completion::complete:rm:*:globbed-files' ignored-patterns
#         zstyle ':fzf-tab:*' fzf-command fzf
#         zstyle ':fzf-tab:*' fzf-flags '--ansi'
#         zstyle ':fzf-tab:complete:cd:*' fzf-preview 'exa -1 --color=always $realpath'
#         zstyle ':fzf-tab:complete:_zlua:*' query-string input
#         zstyle ':fzf-tab:complete:systemctl-*:*' fzf-preview 'SYSTEMD_COLORS=1 systemctl status $word'
#         zstyle ':fzf-tab:*' fzf-bindings \
#           'tab:accept' \
#           'ctrl-y:preview-page-up' \
#           'ctrl-v:preview-page-down' \
#           'ctrl-e:execute-silent(\${VISUAL:-code} \$realpath >/dev/null 2>&1)' \
#           'ctrl-w:execute(\${EDITOR:-nano} \$realpath >/dev/tty </dev/tty)+refresh-preview'
#         zstyle ':fzf-tab:*' fzf-min-height 15
#         zstyle ':fzf-tab:complete:git-(add|diff|restore):*' fzf-preview \
#           'git diff --no-ext-diff \$word | delta --paging=never --no-gitconfig --line-numbers --file-style=omit --hunk-header-style=omit --theme=base16'
#         zstyle ':fzf-tab:complete:git-log:*' fzf-preview \
#           'git --no-pager log --color=always --format=oneline --abbrev-commit --follow \$word'
#         zstyle ':fzf-tab:complete:man:*' fzf-preview \
#           'man -P \"col -bx\" \$word | $FZF_PREVIEW_FILE_COMMAND --language=man'
#         zstyle ':fzf-tab:complete:brew-(install|uninstall|search|info):*-argument-rest' fzf-preview \
#           'brew info \$word'
#         zstyle ':fzf-tab:complete:(-command-|-parameter-|-brace-parameter-|export|unset|expand):*' fzf-preview \
#           'echo \${(P)word}'
#         zstyle ':fzf-tab:complete:*:options' fzf-preview
#         zstyle ':fzf-tab:complete:*:options' fzf-flags '--no-preview'
#         zstyle ':fzf-tab:complete:*:argument-1' fzf-preview
#         zstyle ':fzf-tab:complete:*:argument-1' fzf-flags '--no-preview'
#         zstyle ':fzf-tab:complete:*:*' fzf-preview \
#           '($FZF_PREVIEW_FILE_COMMAND \$realpath || $FZF_PREVIEW_DIR_COMMAND \$realpath) 2>/dev/null'
#           "
# zinit light Aloxaf/fzf-tab

# ### clone vim & compiling
# zinit ice \
#     as"program" \
#     atclone"
#         rm -f src/auto/config.cache;
#         ./configure --with-features=huge --enable-gui=gtk3 --enable-cscope --with-x --enable-multibyte --enable-rubyinterp=yes --enable-perlinterp=yes --enable-python3interp=yes --with-python3-command=/usr/bin/python3 --with-python3-config-dir=/usr/lib/python3.11/config-3.11-x86_64-linux-gnu/ --enable-luainterp=yes --with-compiledby='scudzy@duck.com';
#         make -j4; sudo make install;
#         sudo update-alternatives --install /usr/bin/editor editor /usr/local/bin/vim 10;
#         sudo update-alternatives --set editor /usr/local/bin/vim" \
#     atpull"%atclone" \
#     pick"src/vim"
# zinit light vim/vim


# export FZF_DEFAULT_COMMAND="fd --type file --hidden --follow --exclude .git --color=always"

# # Color Ayu Mirage
# export FZF_DEFAULT_OPTS="
#         --height=60% --layout=reverse
#         --inline-info --border --margin=1 --padding=1
#         --color=fg:#cbccc6,bg:#1f2430,hl:#707a8c
#         --color=fg+:#707a8c,bg+:#191e2a,hl+:#ffcc66
#         --color=info:#73d0ff,prompt:#707a8c,pointer:#cbccc6
#         --color=marker:#73d0ff,spinner:#73d0ff,header:#d4bfff"

# export FZF_CTRL_R_OPTS="
#         --preview 'echo {}' --preview-window up:3:hidden:wrap
#         --bind 'ctrl-/:toggle-preview'
#         --bind 'ctrl-y:execute-silent(echo -n {2..} | clip.exe)+abort'
#         --color header:italic
#         --header 'Press CTRL-Y to copy command into clipboard'"

# ## Preview file content using bat (https://github.com/sharkdp/bat)
# export FZF_CTRL_T_OPTS="
#         --preview 'bat -n --color=always {}'
#         --bind 'ctrl-/:change-preview-window(down|hidden|)'"

# # Use fd (https://github.com/sharkdp/fd) instead of the default find
# # command for listing path candidates.
# # - The first argument to the function ($1) is the base path to start traversal
# # - See the source code (completion.{bash,zsh}) for the details.
# _fzf_compgen_path() {
#   fd --hidden --follow --exclude ".git" . "$1"
# }

# # Use fd to generate the list for directory completion
# _fzf_compgen_dir() {
#   fd --type d --hidden --follow --exclude ".git" . "$1"
# }

# # Advanced customization of fzf options via _fzf_comprun function
# # - The first argument to the function is the name of the command.
# # - You should make sure to pass the rest of the arguments to fzf.
# _fzf_comprun() {
#   local command=$1
#   shift

#   case "$command" in
#     cd)           fzf --preview 'tree -C {} | head -200'   "$@" ;;
#     export|unset) fzf --preview "eval 'echo \$'{}"         "$@" ;;
#     ssh)          fzf --preview 'dig {}'                   "$@" ;;
#     *)            fzf --preview 'bat -n --color=always {}' "$@" ;;
#   esac
# }

# ## only for git
# zstyle ':completion:*:*:git:*' fzf-search-display true
# ## or for everything
# zstyle ':completion:*' fzf-search-display true

# # basic file preview for ls (you can replace with something more sophisticated than head)
# zstyle ':completion::*:ls::*' fzf-completion-opts --preview='eval head {1}'

# # preview when completing env vars (note: only works for exported variables)
# # eval twice, first to unescape the string, second to expand the $variable
# zstyle ':completion::*:(-command-|-parameter-|-brace-parameter-|export|unset|expand):*' fzf-completion-opts --preview='eval eval echo {1}'

# # preview a `git status` when completing git add
# zstyle ':completion::*:git::git,add,*' fzf-completion-opts --preview='git -c color.status=always status --short'

# # if other subcommand to git is given, show a git diff or git log
# zstyle ':completion::*:git::*,[a-z]*' fzf-completion-opts --preview='
#         eval set -- {+1}
#         for arg in "$@"; do
#            { git diff --color=always -- "$arg" | git log --color=always "$arg" } 2>/dev/null
#         done'

### ------------- End of fzf configs ----------------------- ###

### oxipng
zinit ice wait"0b" from"gh-r" \
        mv"oxipng-*x86_64-unknown-linux-gnu* -> oxipng" \
        multisrc"~/.dotfiles/snippets/aliases.zsh ~/.dotfiles/snippets/xdg.zsh /etc/grc.zsh"
zinit light oxipng/oxipng

# zinit ice wait"0a" lucid fpath"~/.dotfiles/zsh/functions" \
#     atload'autoload -Uz ${^fpath[1]}/*(.:t)'
# zinit snippet /dev/null

# pick"oxipng/oxipng"
# bpick"oxipng-*x86_64-unknown-linux-gnu*

# # We don't 'snippet' the folder; we just add it to fpath
# fpath=( ~/.dotfiles/zsh/completions $fpath )

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

# # Function to set window title
# set_window_title() {
#     # You can customize the title format as needed
#     local title="wSL2"
#     echo -ne "\033]0;$title\007"
# }

# # Execute set_window_title before each prompt
# precmd() {
#     set_window_title
# }

# # fix mkdir permission
# if grep -q microsoft /proc/version; then
#     if [ "$(umask)" == '0000' ]; then
#         umask 0022
#     fi
# fi

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

# ### fzf integration with z.lua
# unalias z 2> /dev/null
# z() {
#    [ $# -gt 0 ] && _z "$*" && return
#    cd "$(_z -l 2>&1 | fzf --height 40% --nth 2.. --reverse --inline-info +s --tac --query "${*##-* }" | sed 's/^[0-9,.]* *//')"
# }

# join-lines() {
#   local item
#   while read item; do
#     echo -n "${(q)item} "
#   done
# }

# # Determine git branch.
# parse_git_branch() {
#     git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
# }

# bind-git-helper() {
#   local c
#   for c in $@; do
#     eval "fzf-g$c-widget() { local result=\$(g$c | join-lines); zle reset-prompt; LBUFFER+=\$result }"
#     eval "zle -N fzf-g$c-widget"
#     eval "bindkey '^g^$c' fzf-g$c-widget"
#   done
# }

# bind-git-helper f b t r h
# unset -f bind-git-helper

# function j() {
#     if [[ "$argv[1]" == "-"* ]]; then
#         z "$@"
#     else
#         cd "$@" 2> /dev/null || z "$@"
#     fi
# }

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

### the fuck alias
# eval "$(thefuck --alias)"
#eval $(thefuck --alias --enable-experimental-instant-mode)

# forgit
zinit ice wait lucid
zinit light 'wfxr/forgit'

### ruby env
# eval "$(rbenv init - --no-rehash zsh)"
# source rbenv
# [[ -f '~/.rbenv/completions/rbenv.zsh' ]] || source ~/.rbenv/completions/rbenv.zsh

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

####################### Start of p10k prompt line ##########################

# # After finishing the configuration wizard change the atload'' ice to:
# # -> atload'source ~/.p10k.zsh; _p9k_precmd'
#zinit ice depth"1" atload'true; _p9k_precmd' nocd
# zinit ice depth"1" src"$ZDOTDIR/.p10k.zsh" atload'_p9k_precmd' nocd
# zinit light romkatv/powerlevel10k
# zinit ice depth=1; zinit light romkatv/powerlevel10k

# # To customize prompt, run `p10k configure` or edit ~/.dotfiles/zsh//.p10k.zsh.
# [[ ! -f ~/.dotfiles/zsh//.p10k.zsh ]] || source ~/.dotfiles/zsh//.p10k.zsh
####################### End of p10k prompt line ############################
### Auto Completion -------------- SOURCE BEFORE THIS LINE

# # p10k env var
# POWERLEVEL9K_DISABLE_GITSTATUS="true"
# GITSTATUS_DAEMON="/home/scudzy/.dotfiles/powerlevel10k/gitstatus/usrbin/gitstatusd"
# GITSTATUS_LOG_LEVEL=DEBUG
# typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet

# ## Git prompt
# # autoload -Uz vcs_info
# precmd() { vcs_info }
# zstyle ':vcs_info:git:*' formats '%F{153}%b%f'
# PROMPT='%(?.%F{green}●.%F{red}●%f) %F{211}%1~%f ${vcs_info_msg_0_} '
# RPROMPT='%F{245}%*%f'

# Disable Oh My Zsh's correction features
DISABLE_CORRECTION="true"

# 5. UI & PROMPT
zinit ice depth=1; zinit light romkatv/powerlevel10k
# To customize prompt, run `p10k configure` or edit ~/.dotfiles/zsh//.p10k.zsh.
[[ ! -f ~/.dotfiles/zsh//.p10k.zsh ]] || source ~/.dotfiles/zsh//.p10k.zsh
# Initialize Oh My Posh (choose your themes)
# eval "$(oh-my-posh init zsh --config /home/scudzy/.cache/oh-my-posh/themes/takuya.omp.json)"
#eval "$(oh-my-posh init zsh --config /home/scudzy/.cache/oh-my-posh/themes/markbull.omp.json)"
# eval "$(oh-my-posh init zsh --config /home/scudzy/omp.json)"
#### End OMP #####
#copyq --start-server
# sudo /usr/local/bin/dns-fix.sh
eval "$(direnv hook zsh)"

# Load your local functions directory with "Turbo"
# We add the directory to fpath and autoload the specific functions you named
# zinit ice wait"0" lucid fpath"~/.dotfiles/zsh/functions" \
#     atload'autoload -Uz ipgeo zdic weather bathttp'
# zinit snippet /dev/null

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


