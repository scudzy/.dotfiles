# History configuration
# HISTFILE="$HOME/.zsh_history"
HISTSIZE=500000
SAVEHIST=1000000

# # Options
setopt APPEND_HISTORY          # Add to history, don't overwrite
# setopt SHARE_HISTORY           # Share history between different terminal tabs
# setopt HIST_IGNORE_DUPS        # Don't record the same command twice in a row
# setopt HIST_IGNORE_SPACE       # Don't record commands starting with a space
# setopt HIST_REDUCE_BLANKS      # Remove extra blanks from commands
# setopt HIST_VERIFY             # Don't execute immediately upon history expansion

# --- Proper Zsh History Settings ---
setopt HIST_IGNORE_ALL_DUPS  # Delete old recorded dups, keep only the latest
setopt HIST_SAVE_NO_DUPS      # Don't write duplicate entries to the disk
setopt HIST_REDUCE_BLANKS     # Remove unnecessary whitespace

# The Zsh equivalent of HISTIGNORE
# This function prevents 'ls', 'bg', 'fg', and 'exit' from being saved
zshaddhistory() {
    local line=${1%%$'\n'}
    [[ ! "$line" =~ "^(ls|bg|fg|exit)$" ]]
}

# Your alias is good, move it here to keep aliases grouped
alias history="history 0"
