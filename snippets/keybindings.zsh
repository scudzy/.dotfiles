# Use Emacs mode
bindkey -e

# Use terminfo to get correct keys for your Lenovo/Windows Terminal
typeset -g -A key
key=(
  Home      "${terminfo[khome]}"
  End       "${terminfo[kend]}"
  Insert    "${terminfo[kich1]}"
  Delete    "${terminfo[kdch1]}"
  Up        "${terminfo[kcuu1]}"
  Down      "${terminfo[kcud1]}"
  Left      "${terminfo[kcub1]}"
  Right     "${terminfo[kcuf1]}"
  PageUp    "${terminfo[kpp]}"
  PageDown  "${terminfo[knp]}"
)

# Apply the bindings
[[ -n "${key[Home]}" ]]    && bindkey "${key[Home]}"    beginning-of-line
[[ -n "${key[End]}" ]]     && bindkey "${key[End]}"     end-of-line
[[ -n "${key[Delete]}" ]]  && bindkey "${key[Delete]}"  delete-char

# Keep your specific custom binds
bindkey ' ' magic-space
bindkey '^U' backward-kill-line
bindkey '^[[1;5C' forward-word  # Ctrl + Right
bindkey '^[[1;5D' backward-word # Ctrl + Left
bindkey '^[[Z' undo             # Shift + Tab

# Ctrl+A for aliases full commands
zle -C alias-expension complete-word _generic
bindkey '^a' alias-expension
zstyle ':completion:alias-expension:*' completer _expand_alias

# lf Ctrl+o
bindkey -s '^o' 'lfcd\n'
