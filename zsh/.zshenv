# ~/.zshenv - Loaded for all Zsh instances (interactive & non-interactive)
export DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
export ZDOTDIR="${ZDOTDIR:-$DOTFILES/zsh}"

# Golang environment (defined before PATH inclusion)
export GOROOT="/usr/local/go"
export GOPATH="$HOME/go"
export GOBIN="$HOME/go/bin"
export GOSUMDB="sum.golang.org"
export GOPROXY='https://proxy.golang.org,direct'

# Volta
export VOLTA_HOME="$HOME/.volta"

# Core PATH assembly (deduplicated automatically)
typeset -U path
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$DOTFILES/sh:$GOBIN:$GOROOT/bin:$VOLTA_HOME/bin:$HOME/.local/share/npm/bin:/var/lib/gems/3.1.0/bin:/c/Windows/System32:$PATH"

# XDG Base Directory Specification
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export XDG_CONFIG_DIRS="/etc/xdg"
export XDG_DATA_DIRS="/usr/local/share:/usr/share:/usr/share/gnome"
export XDG_DOTS="$DOTFILES"
export XDG_MENU_PREFIX=debian-
export XDG_CURRENT_DESKTOP="xfce4"
export XDG_SESSION_TYPE=x11
export XDG_SESSION_CLASS=user

# User Dirs
if [[ "$OSTYPE" == linux-gnu ]]; then
  export XDG_DESKTOP_DIR="$HOME/Users/Desktop"
  export XDG_DOCUMENTS_DIR="$HOME/Users/Documents"
  export XDG_DOWNLOAD_DIR="$HOME/Users/Downloads"
  export XDG_MUSIC_DIR="$HOME/Users/Music"
  export XDG_PICTURES_DIR="$HOME/Users/Pictures"
  export XDG_VIDEOS_DIR="$HOME/Users/Videos"
fi

# Display & GUI (GWSL / X11)
export DISPLAY="127.0.0.1:0.0"
export LIBGL_ALWAYS_SOFTWARE=1
export LIBVA_DRIVER_NAME=d3d12
export GDK_BACKEND=x11
export QT_FONT_DPI=96
export QT_SCALE_FACTOR=2
export QT_QPA_PLATFORM=xcb
export NO_AT_BRIDGE=1

# Authority & Session
export ICEAUTHORITY="${XDG_RUNTIME_DIR}/ICEauthority"
export XAUTHORITY="${XDG_RUNTIME_DIR}/Xauthority"
export SCREENDIR="${XDG_RUNTIME_DIR}/screen"

# Tmux
export TMUX_TMPDIR="${XDG_RUNTIME_DIR}/tmux"
export ZSH_TMUX_CONFIG="${XDG_CONFIG_HOME}/tmux/tmux.conf"

# Pager & Documentation
export PAGER="bat"
export BAT_PAGER="less -R -F -+X --mouse"
export BAT_CONFIG_PATH="$XDG_CONFIG_HOME/bat/config"
export BAT_CONFIG_DIR="$XDG_CONFIG_HOME/bat"
export BAT_THEME="Dracula"
export MANPAGER="less -R --use-color -Dd+r -Du+g -S"
export MANPATH="/usr/share/man:$HOME/.local/share/zinit/polaris/man:$HOME/.local/share/zinit/plugins/tj---git-extras/man:${MANPATH:-}"

# Python
export PYTHONPATH="$HOME/.local/lib/python3.13/site-packages"
export PYTHONSTARTUP="$DOTFILES/.pythonrc"

# Pass & Rclone
export PASSWORD_STORE_DIR="$HOME/.password-store"
export PASSWORD_STORE_ENABLE_EXTENSIONS="true"
export PASSWORD_STORE_EXTENSIONS_DIR="$HOME/.password-store/.extensions"
export PASSWORD_STORE_GENERATED_LENGTH="20"
export RCLONE_PASSWORD_COMMAND="pass scudzyDB/garbage/wsl2/rclone-deb12"

# Zsh History File & Sizes
export HISTFILE="$XDG_STATE_HOME/zsh/.zsh_history"
export HISTSIZE=500000
export SAVEHIST=1000000
export HISTORY_IGNORE="(ls|cd|pwd|exit|sudo reboot|history|cd -|cd ..)"

# Locale & Language
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# Less flags
export LESS="-F -i -J -M -R -W -x4 -X -z-4"

# Default Applications
export EDITOR="nvim"
export VISUAL="neovide"
export BROWSER="explorer.exe"
export NAVI_FZF_OVERRIDES_VAR='--height 3'

# Ripgrep
export RG_PREFIX="rg --column --line-number --no-heading --color=always --smart-case"

# gem
export GEM_HOME="$HOME/.local/share/gem/ruby/3.3.0"
export PATH="$GEM_HOME/bin:$PATH"

# Other Tools
export EZA_CONFIG_DIR="$XDG_CONFIG_HOME/eza"
export ZSH_COLORIZE_TOOL="chroma"

# Forgit
export FORGIT_DIFF_FZF_OPTS="--preview-window=right:60%:wrap --ansi"
export FORGIT_DIFF_PAGER="delta --syntax-theme=Dracula"
