
DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
ZDOTDIR="${ZDOTDIR:-$DOTFILES/zsh}"

# zsh only aliases
alias 1='cd -'
alias 2='cd -2'
alias 3='cd -3'
alias 4='cd -4'
alias 5='cd -5'
alias 6='cd -6'
alias 7='cd -7'
alias 8='cd -8'
alias 9='cd -9'

alias cd..='cd ..'
alias -g ..2='../..'
alias -g ..3='../../..'
alias -g ..4='../../../..'
alias -g ..5='../../../../..'
alias -g ...='../..'
alias -g ....='../../..'
alias -g .....='../../../..'
alias -g ......='../../../../..'

# benchmark
alias zbench="export LAZY_PROMPT=false; for i in $(seq 1 10); do time 'zsh -i -c exit'; done; unset LAZY_PROMPT"
alias stresscpu="for i in $(seq $(getconf _NPROCESSORS_ONLN)); do yes > /dev/null & done"

# omp
alias ompv='oh-my-posh --version'
alias omp='oh-my-posh'

# z,lua
alias zh='z -I -t .' # access MRU directories interactively by utilizing parameter -I (fzf) and -t (sort by time):
alias zz='z -c'      # restrict matches to subdirs of $PWD
#alias zi='z -i'      # cd with interactive selection
alias zf='z -I'      # use fzf to select in multiple matches
alias zb='z -b'      # quickly cd to the parent directory

### Manpages
alias mank="man -k $@"
alias manf="man -f $@"

# zsh pipes
alias -g H='| head'
alias -g T='| tail'
alias -g G='| grep -E'
alias -g S='| sort'
alias -g L='| less'
alias -g M='| more'

# Colorize
alias -g -- -h='-h 2>&1 | bat --language=help --style=plain'
alias -g -- --help='--help |& bat --language=help --style=plain'

# subversion
alias svn="svn --config-dir \"$XDG_CONFIG_HOME\"/subversion"

# mask built-ins with better defaults
alias grep='grep --color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn}'
alias ping="ping -c5 $@"
alias hp3="hping3 --icmp --count 5 $@"

# be safe
alias cpi='cp -i'
alias mvi='mv -i'
alias rmi='rm -i'

# single character shortcuts - be sparing!
alias _='sudo'
alias c='clear'
alias d='dirs -v | head -10'
alias v='nvim'
alias h='history'

# shortcuts
alias vi='nvim'   # vim is not installed; everything goes through nvim
alias nv='nvim'
alias nvide='neovide --wsl --neovim-bin /home/scudzy/.local/share/zinit/plugins/neovim---neovim/nvim-linux-x86_64/bin/nvim'
alias afind='ack -il'
alias md='mkdir -p'
alias rd=rmdir
alias please=sudo
alias po=popd
alias pu=pushd
alias globurl='noglob urlglobber '
alias qq=exit
alias rgc="rg -n --no-heading --color=always"

# network
alias ipext="dig +short myip.opendns.com @resolver1.opendns.com"
alias iplocal="ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'"
alias dnsflush="dscacheutil -flushcache && killall -HUP mDNSResponder"
alias speedtestw="wget -O /dev/null http://speed.transip.nl/10mb.bin"
alias speedtestp="curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python -"
alias pinging="command ping"

# other aliases
alias tarls="tar -tvf"
alias untar="tar -xf"
alias biggest='du -s ./* | sort -nr | awk '\''{print $2}'\'' | xargs du -sh'
alias dux='du -x --max-depth=1 | sort -n'
alias path="print -l $path"
alias manpath="print -l $manpath"
alias fpath="print -l $fpath"

alias linecount="grep -c '^'"
alias ts="date +%d%m%Y-%H%M%S"
#alias timestamp="date '+%Y-%m-%d %H:%M:%S'"
#alias datestamp="date '+%Y-%m-%d'"
alias dus="du -had 1 | sort -rh"

# auto-orient images based on exif tags
alias autorotate="jhead -autorot"

# ls
alias ld="eza -lahgDoT -L=1 --icons"
#alias lld="eza -laho --icons"
alias ll="eza -laho --icons --group-directories-first" # without group IDs
alias lg="eza -lahog --icons --group-directories-first" # with group IDs

alias l1="eza -lahoT -L=1 --icons --group-directories-first" # depth 1
alias l2="eza -lahoT -L=2 --icons --group-directories-first" # depth 2

alias llg="eza -lahoG --icons --group-directories-first" # Grid view

alias lg1="eza -lahoT -L=1 --icons --group-directories-first --git" # status of files in git
alias lg2="eza -lahoT -L=1 --icons --group-directories-first --git-repos" # git repos
alias lgg="eza -lahoT -L=1 --icons --group-directories-first --git --git-repos" # repos & files

# sh
alias ffmpegts="sh -c '$DOTFILES/sh/ffmpegts.sh'"

# pass
alias passgp="pass git push -u --all --verbose"
alias potp="pass otp $@"
alias pcp="pass -c $@"
alias psh="pass show $@"
alias pins="pass insert -m $@"
alias pgen="pass generate $@"
alias prm="pass rm $@"
alias pfd="pass find $@"
alias pgp="pass grep $@"
alias sh-otp="pass otp uri -q \$1 | qrencode -t utf8"

alias genpass="head -c 20 /dev/urandom | base64 | head -c 28; echo"
alias genpass1="LC_ALL=C tr -dc 'A-Za-z0-9!@#$%^&*()_+' < /dev/urandom | head -c 28; echo"
alias genpass2='openssl rand -base64 20'

alias mybsn="pass show scudzyDB/garbage/My/MyBSN"
alias 2u="pass show scudzyDB/garbage/My/Maybank2u"
alias gscudzy="pass show scudzyDB/IDs/Google-scudzy"
alias ghalimi="pass show scudzyDB/IDs/Google-halimi"

# others
alias c="calc $@"
alias suu="sudo apt update && sudo apt upgrade -y"
alias dfh="df -h $@"
alias dush="du -csh $@"
alias stats="stat -c '%A %a %n' $@" ### "stat -c '%a' $@"#
alias speed="speedtest --selection-details -v"
alias zuu="zi self-update && zi update"

# nohup
alias noxterm="nohup xfce4-terminal >/dev/null 2>&1 & sleep 3s"
alias nothun="nohup thunar >/dev/null 2>&1 & sleep 3s"
alias noqt="nohup qtpass >/dev/null 2>&1 & sleep 3s"
alias noff="nohup firefox >/dev/null 2>&1 & sleep 3"

# weather
alias wttr="curl -s 'wttr.in/Kuantan?0qTm'"
alias wttr4="curl -s 'wttr.in/Kuantan?format=4'"

# rclone
alias rclGdrvd="rclone --exclude ".git/" sync "$DOTFILES" 'Gdrive:/dotfiles/Debian' --track-renames --checkers=16 --transfers=16 --stats=1s --tpslimit=10 --tpslimit-burst=10 -u -P -v"     # Debian
alias rclGdrvu="rclone --exclude ".git/" sync "$DOTFILES" 'Gdrive:/dotfiles/Ubuntu' --track-renames --checkers=16 --transfers=16 --stats=1s --tpslimit=10 --tpslimit-burst=10 -u -P -v"     # Ubuntu

alias rclone-docs="rclone sync '/d/OneDrive/Documents/Business Doc/' 'G-halimi:/Documents/' --transfers=8 --stats=1s --drive-chunk-size=128M --tpslimit=10 --tpslimit-burst=10 --create-empty-src-dirs -u -P -v"

# python
alias cc="currency_converter"
alias pipxu="pipx upgrade-all --verbose"
alias pipxi="pipx install"
alias pipxun="pipx uninstall"
alias pipr="pip-review --local --interactive --verbose --no-cache-dir"
alias pip="pip3"
alias pip3i="python3 -m pip install"
alias pip3u="pip3 uninstall"
alias p3="python3"
alias pyupg="pip3 list --outdated --format=freeze | grep -v '^\-e' | cut -d = -f 1 | xargs -n1 pip3 install -U"

alias eurofx="curl -LOf https://www.ecb.europa.eu/stats/eurofxref/eurofxref-hist.zip && mv -fv eurofxref-hist.zip $HOME/.local/share/pipx/venvs/currencyconverter/lib/python3.13/site-packages/currency_converter/eurofxref-hist.zip"


# apt & dpkg
# -oDebug::pkgAcquire::Worker=1 --- Add for verbose debug
alias aptsh="sudo apt show"
alias apti="sudo apt install"
alias aptino="sudo apt install --no-install-recommends"
alias aptar="sudo apt autoremove"
alias aptcs="apt-cache search '' | sort | cut --delimiter ' ' --fields 1 | fzf --multi --cycle --reverse --preview 'apt-cache show {1}' | xargs -r"
alias apts="apt search"
alias aptrd="apt-rdepends"
alias aptli="apt list --installed"
alias dpigs20="dpigs --lines=20 -SH"

# fzf
alias fzfb="fzf --preview 'bat --color=always --style=numbers --line-range=:500 {}'"

# geo location ip
alias geoloc="curl -s --request GET --url https://freegeoip.app/json/ --header 'accept: application/json' --header 'content-type: application/json' | jq "

# path
alias dot="cd $DOTFILES"
alias zz="cd $ZDOTDIR"
alias zplug="cd ~/.local/share/zinit/plugins"
alias zsnip="cd ~/.local/share/zinit/snippets"
alias zpol="cd ~/.local/share/zinit/polaris"
alias timezsh="time-n-cmd 5 'zsh -i -c exit' 2>&1 > /dev/null"

# git
alias gst="git status"
alias gss="git status -s"
alias gp="git push --verbose"
alias gitlg="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
alias gcom="git commit -m $@"
alias rmgitd="find . -type d -name ".git" -exec rm -rf {} +"

# terminal
alias term-size='echo "Rows=$(tput lines) Cols=$(tput cols)"'

# Trash
alias del="trash-put $@"
alias tempty="trash-empty $@"
alias trestore="restore-trash $@"
alias tlist="trash-list"
alias td="tldr"

# dns
alias dns1='echo -e "nameserver 1.1.1.1\nnameserver 8.8.8.8\n" | sudo tee /etc/resolv.conf'
alias dns8="echo nameserver 8.8.8.8 | sudo tee -a /etc/resolv.conf"

# others
alias ipa="ip address show eth0"
alias gduns="gdu -ns --si $@"
alias gduna="gdu -na --si $@"
alias gdun="gdu -n --si $@"
alias rmrf="rm -rfv $@"
alias s256="sha256sum $@"
alias rld="omz reload"
alias gpgpwd="gpg --gen-random --armor 1 8"

# bat alias
alias bwsl="bat /etc/wsl.conf"
alias bresolv="bat /etc/resolv.conf"
alias bgenie="bat /etc/genie.ini"

# sed
alias sedhtml="sed 's/<\/*[^>]*>//g'"
alias encode="openssl enc -base64 <<< $@"
alias decode="openssl enc -base64 -d <<< $@"

# brew
alias brewuu="brew update -v && brew upgrade -v && exec zsh"
alias brewup="brew upgrade $@ -v"
alias brewl="brew list"
alias brewi="brew install $@ -v"
alias brewun="brew uninstall $@ -v"

# rclone
alias rcl1="rclone about G-scudzy: && printf '\e[1;31mscudzy@gmail.com \e[0m\n'"
alias rcl2="rclone about G-mhmk770922: && printf '\e[1;34mmhmk770922@gmail.com \e[0m\n'"
alias rcl3="rclone about G-halimi: && printf '\e[1;34mhalimi@barikatech.com \e[0m\n'"
alias rcl4="rclone about O-scudzy: && printf '\e[1;31mscudzy@outlook.com \e[0m\n'"
alias rcl5="rclone about D-scudzy: && printf '\e[1;31mDropbox-scudzy \e[0m\n'"
alias rcl6="rclone about mega-scudzy: && printf '\e[1;31mMega-scudzy \e[0m\n'"

# search installed packages
alias dpin="dpkg-query -Wf '${Installed-Size}\t${Package}\n' | sort -n"

# google cloud cli
alias gc-s="gcloud cheat-sheet"

# shutdown & reboot
alias shutdown="wsl.exe --shutdown $WSL_DISTRO_NAME"
alias reboot="wsl.exe --terminate $WSL_DISTRO_NAME"

# fpath
alias fpath="print -l $fpath"

# open ports
alias oports="ss -tuln"

# curl alias
alias curlsv="curl -v -sfLO $@"

# gemini
alias gemini='cd ~/.gemini && gemini'

# golazo update
alias golazou='curl -fsSL https://raw.githubusercontent.com/0xjuanma/golazo/main/scripts/install.sh | bash'

# witr update
alias witrup='curl -fsSL https://raw.githubusercontent.com/pranshuparmar/witr/main/install.sh | bash'

# gh origin glab main
alias gppghglab="git push origin main -v && git push gitlab main -v"
# glab origin gh main
alias gppglabgh="git push origin main -v && git push github main -v"

# st4
alias zshrc='neovide ~/.dotfiles/zsh/.zshrc &'
alias zshenv='neovide ~/.dotfiles/zsh/.zshenv &'
alias zprofile='neovide ~/.dotfiles/zsh/.zprofile &'
alias nvide='neovide ~/.dotfiles/snippets/aliases.zsh &'
alias tmux='tmux -f ~/.tmux.conf'
