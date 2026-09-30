# .zshrc
# Start the timer using Zsh built-ins (Faster than calling 'date')
# Capture start time in milliseconds
  ZSH_START_TIME=$(( $(gdate +%s%N 2>/dev/null || date +%s%N) / 1000000 ))

  zmodload zsh/datetime

# Load Profiler (Only if you need to debug; otherwise, comment it out)
  zmodload zsh/zprof
  zmodload zsh/stat

# This tells Zinit to skip its internal compinit call.
  ZINIT_COMPINIT_SKIP=1
# # COMPLETION CACHING (Place this at the VERY top)
# # This prevents compinit from running 3 times and skips disk scans if the cache is fresh.
#   autoload -Uz compinit
#   if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.m-1) ]]; then
#     compinit -C
#   else
#     compinit
#   fi

  # Fast compinit initialization with 24-hour cache validation
  autoload -Uz compinit
  local zcompdump="${ZDOTDIR:-$HOME}/.zcompdump"

  # Check if compdump exists and is less than 24 hours old (mtime -1)
  if [[ -s "$zcompdump" && $(zstat +mtime "$zcompdump") -gt $(($(date +%s) - 86400)) ]]; then
    compinit -C -d "$zcompdump"
  else
    compinit -d "$zcompdump"
  fi

  # Compile zcompdump in the background if uncompiled
  if [[ -s "$zcompdump" && ! "$zcompdump.zwc" -nt "$zcompdump" ]]; then
    zcompile "$zcompdump"
  fi
  # end of compinit

# Load Zinit
  if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
      print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
      command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
      command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
      print -P "%F{33} %F{34}Installation successful.%f%b" || \
      print -P "%F{160} The clone has failed.%f%b"
  fi
  source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"

# Define Paths and fpath
  export DOTFILES="$HOME/.dotfiles"
  export ZDOTDIR="$DOTFILES/zsh"
  export SNIPPETS="$DOTFILES/snippets"
  export FZF_BASE="$HOME/.local/share/zinit/plugins/junegunn---fzf"
  export PATH="$FZF_BASE:$PATH"
  export _ZL_FZF="fzf"
  export _ZL_MATCH_MODE=1
  export _ZL_FZF_FLAG="--height 40% --reverse --border --ansi"

# TURBO MODE FOR PLUGINS
# Load the prompt IMMEDIATELY so you see a shell fast
### powerline-go prompt
  # function powerline_precmd() {
  #     eval "$($GOPATH/bin/powerline-go -error $? -shell zsh -eval -modules-right git)"
  # }

  # function install_powerline_precmd() {
  #   for s in "${precmd_functions[@]}"; do
  #     if [ "$s" = "powerline_precmd" ]; then
  #       return
  #     fi
  #   done
  #   precmd_functions+=(powerline_precmd)
  # }

  # if [ "$TERM" != "linux" ]; then
  #     install_powerline_precmd
  # fi
### powerline-go prompt

# Syntax Highlighting & Autosuggestions
  zinit ice wait'0a' lucid
  zinit light zsh-users/zsh-autosuggestions

  zinit ice wait'0b' lucid
  zinit light zdharma-continuum/fast-syntax-highlighting


# load zinit modules
  zinit light-mode for \
    zdharma-continuum/zinit-annex-{'readurl','bin-gem-node','patch-dl','rust'}

# --- 3. Load Heavy Plugins (Turbo Mode: 1 second) ---
# We delay these slightly because they were your main bottlenecks.
  zinit wait'1' lucid for \
      zdharma-continuum/history-search-multi-word \
      zsh-users/zsh-history-substring-search

# zstyle ":history-search-multi-word" page-size "11"
### diff-so-fancy
  zinit ice wait"1" lucid as"program" pick"bin/git-dsf"
  zinit load zdharma-continuum/zsh-diff-so-fancy

# automatically remove duplicates from these arrays
  typeset -U path cdpath fpath manpath
  # Add custom functions to fpath (using -U to keep the array unique)
  typeset -gU fpath
  # fpath=( "$DOTFILES/zsh/functions" $fpath )

# Zinit block
  zinit ice wait"0a" lucid
  zinit snippet ~/.dotfiles/snippets/completion.zsh

  zinit ice wait"0a" lucid; zinit snippet ~/.dotfiles/snippets/options.zsh
  zinit ice wait"0a" lucid; zinit snippet ~/.dotfiles/snippets/history.zsh
  zinit ice wait"0a" lucid; zinit snippet ~/.dotfiles/snippets/keybindings.zsh
  zinit ice wait"0a" lucid; zinit snippet ~/.dotfiles/snippets/env.zsh
  zinit ice wait"0a" lucid; zinit snippet ~/.dotfiles/snippets/functions.zsh

# dircolors: Only run if it exists
  if [ -x /usr/bin/dircolors ]; then
      test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
      export LS_COLORS="$LS_COLORS:ow=30;44:"
  # Link LS_COLORS to completion (Do this AFTER dircolors)
      zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
      zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
  fi
# Use your existing Zinit plugin for Man colors

# Load extra completions (Turbo Mode)
  zinit ice wait'0' lucid blockf atpull'zinit creinstall -q .'
  zinit light zsh-users/zsh-completions

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

# Add this to confirm fzf is on PATH when z.lua loads
  zinit ice wait'!0' lucid
  zinit light skywind3000/z.lua

### b4b4r07/httpstat
  zinit ice lucid wait as"program" pick"httpstat"
  zinit light b4b4r07/httpstat

### dalance/procs
  zinit for from'gh-r' sbin'**/procs -> procs' dalance/procs

### zsh-vi-man
  zinit light TunaCuma/zsh-vi-man
  source /home/scudzy/.local/share/zinit/plugins/TunaCuma---zsh-vi-man/zsh-vi-man.plugin.zsh

### dbrgn/tealdeer
  zinit ice lucid wait from"gh-r" as"command" bpick"tealdeer-linux-x86_64-musl" pick"tldr" \
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
          mv -vf *.1 ${ZINIT[MAN_DIR]}/man1" \
        @junegunn/fzf

# FZF and History (Fixes the 2.2s fzf-history-widget lag)
  zinit ice wait'0' lucid
  zinit light Aloxaf/fzf-tab

# Load all FZF variables, functions, and zstyles in the background
  zinit ice wait"0b" lucid
  zinit snippet ~/.dotfiles/snippets/fzf.zsh

# Slot 0b: Load after your core UI is ready
  zinit ice wait"1" lucid \
        atload'unalias grc'
  zinit light 'wfxr/forgit'

# oxipng - multisrc cargo & grc
  zinit ice wait"0b" lucid from"gh-r" \
          mv"oxipng-*x86_64-unknown-linux-gnu* -> oxipng" \
          multisrc"~/.cargo/env ~/.dotfiles/snippets/aliases.zsh ~/.dotfiles/snippets/xdg.zsh /etc/grc.zsh"
  zinit light oxipng/oxipng

  # dynamic aliases
  if (( $+commands[grc] )) && [[ -d /usr/share/grc ]]; then
      for conf in /usr/share/grc/conf.*; do
          cmd="${conf##*conf.}"
          (( $+commands[$cmd] )) && alias "$cmd"="grc --colour=auto $cmd"
      done
  fi
########################## End of zinit line #############################

# xterm modes
  if [ "$TERM" != "xterm-256color" ]; then
      export TERM=xterm-256color
  fi

# bathelp
  alias bathelp='bat --plain --language=help'
  help() {
      "$@" --help 2>&1 | bathelp
  }

# fzf pass ZSH
  _fzf_complete_pass() {
    _fzf_complete +m -- "$@" < <(
      local prefix
      prefix="${PASSWORD_STORE_DIR:-$HOME/.password-store}"
      command find -L "$prefix" \
        -name "*.gpg" -type f | \
        sed -e "s#${prefix}/\{0,1\}##" -e 's#\.gpg##' -e 's#\\#\\\\#' | sort
    )
  }

# # Load powerline daemon and go-binary asynchronously
#   zinit ice wait"0" lucid atload'powerline-daemon -q'
#   zinit snippet /home/scudzy/.config/powerline/zsh/powerline.zsh

# # Setup powerline-go in a hook
#   precmd_functions+=(powerline_precmd)
#     powerline_precmd() {
#       PS1="$(/usr/bin/powerline-go -error $? -jobs ${${(%):%j}:-0})"
#     }
# # end of powerline-status

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

# Disable Oh My Zsh's correction features
  DISABLE_CORRECTION="true"

# Slot 0a: Load local functions
  zinit ice wait"0a" lucid as"null" \
      atinit'fpath+=( "$HOME/.dotfiles/zsh/functions" )' \
      atload'autoload -Uz $HOME/.dotfiles/zsh/functions/*(.:t)'
  zinit snippet /dev/null

# Slot 0b: Your Completions
  zinit ice wait"0b" lucid as"completion" \
      atload'zinit creinstall ~/.dotfiles/zsh/completions > /dev/null 2>&1'
  zinit snippet /dev/null

### ---------- Checking Login v.s. Non-Login ---------- ###
  if [[ -o Login ]]; then
      echo "Login"
      echo ""
      fastfetch -c ~/.config/fastfetch/archey.jsonc
      # gotcha
      echo ""
  else
      echo "Non-Login"
      echo ""
      fastfetch -c ~/.config/fastfetch/examples/8.jsonc
      echo ""
  fi

  # omp
    # eval "$(oh-my-posh init zsh --config $HOME/.cache/oh-my-posh/themes/illusi0n.omp.json)"
    # eval "$(oh-my-posh init zsh --config $HOME/.cache/oh-my-posh/themes/craver.omp.json)"
  eval "$(oh-my-posh init zsh --config $HOME/.cache/oh-my-posh/themes/stelbent.minimal.omp.json)"

# translate-shell completion
  compdef _gnu_generic trans

  # Create $XDG_RUNTIME_DIR if missing, then symlink Wayland socket
  if [ -e /wslg/runtime-dir/wayland-0 ]; then
      export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
      [ ! -d "$XDG_RUNTIME_DIR" ] && mkdir -p -m 700 "$XDG_RUNTIME_DIR" 2>/dev/null
      ln -sf /wslg/runtime-dir/wayland-0 "$XDG_RUNTIME_DIR/wayland-0" 2>/dev/null
      ln -sf /wslg/runtime-dir/wayland-0.lock "$XDG_RUNTIME_DIR/wayland-0.lock" 2>/dev/null
  fi

# # NVM
# export NVM_DIR="$HOME/.config/nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

  # Lazy-load NVM
  export NVM_DIR="$HOME/.config/nvm"
  nvm() {
      unset -f nvm node npm yarn
      [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
      [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
      nvm "$@"
  }
  node() { nvm >/dev/null; node "$@"; }
  npm()  { nvm >/dev/null; npm "$@"; }
  yarn() { nvm >/dev/null; yarn "$@"; }

  # dotenv
  . "$HOME/.local/share/../bin/env"

  # Use default trigger (type '**' then TAB for fzf, regular TAB otherwise)
  export FZF_COMPLETION_TRIGGER='**'

  # Re-bind standard Tab key to native Zsh completion
  bindkey '^I' expand-or-complete

# Place this at the absolute bottom of your .zshrc, after all Zinit commands

  # Time profiles
  # Place this at the very end of your .zshrc
  _print_shell_load_time() {
      # Calculate end time
      ZSH_END_TIME=$(( $(gdate +%s%N 2>/dev/null || date +%s%N) / 1000000 ))
      ZSH_LOAD_TIME=$(( ZSH_END_TIME - ZSH_START_TIME ))
      ZSH_LOAD_SECONDS=$(( ZSH_LOAD_TIME / 1000.0 ))

      # Print the message
      printf "\n\e[1m🚀 Shell loaded in \e[32m%.3f\e[0m \e[1mseconds\e[0m\n\n\n" "$ZSH_LOAD_SECONDS"

      # Self-destruct so it only runs once on shell startup, not on every command
      add-zsh-hook -d precmd _print_shell_load_time
  }

# Load the hook module and register the function
autoload -Uz add-zsh-hook
add-zsh-hook precmd _print_shell_load_time

# Show zprof results if it was loaded
  #zprof

# pnpm
export PNPM_HOME='/home/scudzy/.local/share/pnpm'
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac
# pnpm end
