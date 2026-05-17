# ~/.zshenv should only be a one-liner that sources this file
# echo "source ~//.config/zsh/.zshenv" >| ~//.zshenv
export ZDOTDIR="$HOME/.dotfiles/zsh"
export DOTFILES="$HOME/.dotfiles"

# If you come from bash you might have to change your $PATH.
export PATH="/home/scudzy/.cargo/bin:/home/scudzy/.huber/bin:/home/scudzy/.local/bin:/home/scudzy/.dotfiles/sh:/c/Windows/System32:/home/scudzy/go/bin:/var/lib/gems/3.1.0/:/home/scudzy/.local/share/npm/bin/:$GOROOT:$GOPATH:$PATH"

# Set XDG dirs
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_RUNTIME_DIR="/run/user/1000/"
export XDG_CONFIG_DIRS="/etc/xdg"
export XDG_DATA_DIRS="/usr/local/share:/usr/share:/usr/share/gnome"
export XDG_DOTS="$HOME/.dotfiles"
export XDG_MENU_PREFIX=debian-
export XDG_CURRENT_DESKTOP="xfce4"
export XDG_SESSION_TYPE=x11
export XDG_SESSION_CLASS=user

# Disables using Direct3D in Mesa 3D graphics library
export LIBGL_ALWAYS_SOFTWARE=1
# Force WSL2 to use DirectX 12 for video acceleration
export LIBVA_DRIVER_NAME=d3d12
# export GALLIUM_DRIVER=d3d12
# Use software rendering instead of broken hardware acceleration
# export LIBVA_DRIVER_NAME=swrast
# export GDK_BACKEND=x11
# export SWAYSOCK=/run/user/1000/sway-ipc.1000.20169.sock

# Adjust the number (96, 120, or 144) until it looks right on the 24" screen
export QT_FONT_DPI=96

# Force apps to prefer Wayland over X11
export XDG_SESSION_TYPE=wayland
export MOZ_ENABLE_WAYLAND=1  # For Firefox
export QT_QPA_PLATFORM=wayland

export ICEAUTHORITY="${XDG_RUNTIME_DIR}ICEauthority"
export XAUTHORITY="${XDG_RUNTIME_DIR}Xauthority"
export SCREENDIR="${XDG_RUNTIME_DIR}screen"

### tmux
export TMUX_TMPDIR="${XDG_RUNTIME_DIR}tmux"
export ZSH_TMUX_CONFIG="${XDG_CONFIG_HOME}/tmux/tmux.conf"

# user-dirs
if [[ "$OSTYPE" == linux-gnu ]]; then
  export XDG_DESKTOP_DIR="$HOME/Users/Desktop"
  export XDG_DOCUMENTS_DIR="$HOME/Users/Documents"
  export XDG_DOWNLOAD_DIR="$HOME/Users/Downloads"
  export XDG_MUSIC_DIR="$HOME/Users/Music"
  export XDG_PICTURES_DIR="$HOME/Users/Pictures"
  export XDG_VIDEOS_DIR="$HOME/Users/Videos"
fi

# bat
export PAGER="less"
export BAT_PAGER="less -R -F -+X --mouse"
export BAT_CONFIG_PATH="$HOME/.config/bat/config"
export BAT_CONFIG_DIR="$HOME/.config/bat"
export BAT_THEME="Dracula"
export MANPAGER="less -R --use-color -Dd+r -Du+g -S"
# export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export MANPATH="/usr/share/man:~/.local/share/zinit/polaris/man:~/.local/share/zinit/plugins/tj---git-extras/man"

### golang
export GOROOT="$HOME/.local/go"
export GOPATH="$HOME/go"
export GOBIN="$HOME/go/bin"
export GOSUMDB="sum.golang.org"
export GOPROXY='https://proxy.golang.org,direct'

### python
# export PYTHONHOME="/usr/lib/python3.11"
export PYTHONPATH="$HOME/.local/lib/python3.13/site-packages"
export PYTHONSTARTUP="$HOME/.dotfiles/.pythonrc"

### pass
export PASSWORD_STORE_DIR="$HOME/.password-store"
export PASSWORD_STORE_ENABLE_EXTENSIONS="true"
export PASSWORD_STORE_EXTENSIONS_DIR="$HOME/.password-store/.extensions"
export PASSWORD_STORE_GENERATED_LENGTH="20"
# export PASSWORD_STORE_TOMB="/usr/bin/tomb"
# export PASSWORD_STORE_TOMB_FILE="~/.password.tomb"
# export PASSWORD_STORE_TOMB_KEY="~/.password.key.tomb"
# export PASSWORD_STORE_TOMB_SIZE=10

# Zsh History Ignore
export HISTORY_IGNORE="(ls|cd|pwd|exit|sudo reboot|history|cd -|cd ..)"

### rclone
export RCLONE_PASSWORD_COMMAND="pass scudzyDB/garbage/wsl2/rclone-deb12"

# ### cowsay
# export COWPATH="/usr/share/cowsay/cows/"

# wsl2 display
export WSL2IP="$(ip addr show eth2 | grep inet | awk '{print $2; exit;}' | sed 's/\(.*\).\{3\}$/\1/' )"
# export DISPLAY=:0
export NO_AT_BRIDGE=1

# # thefuck
# export THEFUCK_RULES='sudo:no_command'
# export THEFUCK_EXCLUDE_RULES='git_pull:git_push'
# export THEFUCK_REQUIRE_CONFIRMATION='true'
# export THEFUCK_WAIT_COMMAND=10
# export THEFUCK_NO_COLORS='false'
# export THEFUCK_PRIORITY='no_command=9999:apt_get=100'
# export THEFUCK_HISTORY_LIMIT='2000'
# export THEFUCK_NUM_CLOSE_MATCHES='5'

### hisory bash or zsh
# export HISTFILE="/.local/state/bash/history"
export HISTFILE="$HOME/.local/state/zsh/.zsh_history"
export HISTSIZE=100000; # Larger bash history (allow 32³ entries; default is 500)
export HISTFILESIZE=$HISTSIZE;
export HISTCONTROL=ignoredups; # Remove duplicates from history. I use `git status` a lot.
export HISTIGNORE="ls:cd:cd -:pwd:exit:date:* --help"; # Make some commands not show up in history
export HISTTIMEFORMAT="%F-%T ";
export SAVEHIST=$HISTSIZE;

### language
export LANG="en_US.UTF-8"; # Language formatting is still important
export LC_ALL="en_US.UTF-8"; # byte-wise sorting and force language for those pesky apps

# set options for less
# export LESS="--quit-if-one-screen --ignore-case --status-column --LONG-PROMPT --RAW-CONTROL-CHARS --HILITE-UNREAD --tabs=4 --no-init --window=-4"
# or the short version
export LESS="-F -i -J -M -R -W -x4 -X -z-4"

# Default apps
export EDITOR="nano"
export VISUAL="nano"
export BROWSER="/c/Users/scudz/AppData/Local/BraveSoftware/Brave-Browser/Application/brave.exe"
export NAVI_FZF_OVERRIDES_VAR='--height 3'

# Ripgrep
export RG_PREFIX="rg --column --line-number --no-heading --color=always --smart-case"
#export RIPGREP_CONFIG_PATH="~/.dotfiles/.ripgreprc"
#export RG_PREFIX="rg --column -n --no-heading --color=always -S --max-columns=150 "

### Powerline-status
export POWERLINE_LOCATION="$HOME/.local/share/pipx/venvs/powerline-status/bin/powerline"
export POWERLINE_CONFIG_COMMAND="$HOME/.local/bin/powerline-config"
export POWERLINE_ZSH_CONTINUATION="1"
export POWERLINE_ZSH_SELECT="1"

### p10k & Gitstatus
export POWERLEVEL9K_DISABLE_GITSTATUS="true"
export GITSTATUS_LOG_LEVEL=DEBUG
export POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true
export POWERLEVEL9K_VCS_MAX_INDEX_SIZE=10000000
typeset -g P10K_INSTANT_PROMPT=quiet
typeset -g POWERLEVEL9K_INSTANT_PROMPT=off

### Gemini Cli
export GOOGLE_GENAI_USE_VERTEXAI=true

### GCloud
export GOOGLE_CLOUD_PROJECT=scudzy
export GOOGLE_CLOUD_LOCATION=asia-southeast1

### local library paths
export LD_LIBRARY_PATH="/usr/lib/x86_64-linux-gnu"
export PKG_CONFIG_PATH="/usr/lib/x86_64-linux-gnu/pkgconfig:/usr/share/pkgconfig"
export LDFLAGS="-L/usr/lib"
export CPPFLAGS="-I/usr/include"
export RUBYLIB="/usr/lib/x86_64-linux-gnu/ruby/vendor_ruby/"

### GWSL
export QT_SCALE_FACTOR=2
export fdatetime="$(date +%d%m%Y-%H%M)"
export NVM_DIR="$HOME/.config/nvm"
export NVM_RC_VERSION="v25.2.1"
export EZA_CONFIG_DIR="$HOME/.config/eza"
export ZSH_COLORIZE_TOOL="chroma"
