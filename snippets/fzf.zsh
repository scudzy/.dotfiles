# --- FZF Environment Variables ---
export FZF_DEFAULT_COMMAND="fd --type file --hidden --follow --exclude .git --color=always"

# Color Ayu Mirage
export FZF_DEFAULT_OPTS="
        --height=60% --layout=reverse
        --inline-info --border --margin=1 --padding=1
        --color=fg:#cbccc6,bg:#1f2430,hl:#707a8c
        --color=fg+:#707a8c,bg+:#191e2a,hl+:#ffcc66
        --color=info:#73d0ff,prompt:#707a8c,pointer:#cbccc6
        --color=marker:#73d0ff,spinner:#73d0ff,header:#d4bfff"

export FZF_CTRL_R_OPTS="
        --preview 'echo {}' --preview-window up:3:hidden:wrap
        --bind 'ctrl-/:toggle-preview'
        --bind 'ctrl-y:execute-silent(echo -n {2..} | clip.exe)+abort'
        --color header:italic
        --header 'Press CTRL-Y to copy command into clipboard'"

## Preview file content using bat (https://github.com/sharkdp/bat)
export FZF_CTRL_T_OPTS="
        --preview 'bat -n --color=always {}'
        --bind 'ctrl-/:change-preview-window(down|hidden|)'"

# Use fd (https://github.com/sharkdp/fd) instead of the default find
# command for listing path candidates.
# - The first argument to the function ($1) is the base path to start traversal
# - See the source code (completion.{bash,zsh}) for the details.
_fzf_compgen_path() {
  fd --hidden --follow --exclude ".git" . "$1"
}

# Use fd to generate the list for directory completion
_fzf_compgen_dir() {
  fd --type d --hidden --follow --exclude ".git" . "$1"
}

# Advanced customization of fzf options via _fzf_comprun function
# - The first argument to the function is the name of the command.
# - You should make sure to pass the rest of the arguments to fzf.
_fzf_comprun() {
  local command=$1
  shift

  case "$command" in
    cd)           fzf --preview 'ls -1p --color=always {} | head -200' "$@" ;;
    export|unset) fzf --preview "eval 'echo \$'{}"         "$@" ;;
    ssh)          fzf --preview 'dig {}'                   "$@" ;;
    *)            fzf --preview 'bat -n --color=always {}' "$@" ;;
  esac
}

# --- FZF Zstyles (Completions) ---
zstyle ':completion:*:*:git:*' fzf-search-display true
zstyle ':completion:*' fzf-search-display true

# Better ls preview using bat
zstyle ':completion::*:ls::*' fzf-completion-opts --preview='bat --color=always --style=numbers --line-range :50 {1} 2>/dev/null || head -n 50 {1}'

# Git add preview
zstyle ':completion::*:git::git,add,*' fzf-completion-opts --preview='git -c color.status=always status --short'

# Complex Git Subcommand Preview
zstyle ':completion::*:git::*,[a-z]*' fzf-completion-opts --preview='
        eval set -- {+1}
        for arg in "$@"; do
           { git diff --color=always -- "$arg" | git log --color=always "$arg" } 2>/dev/null
        done'
