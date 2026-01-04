# Professional time format for performance monitoring
export TIMEFMT=$'\n========================\nProcess: %J\nTotal:   %E\nUser:    %U\nSystem:  %S\nCPU:     %P\n========================'
### zsh-vi-man
# Vi normal mode key (default: K)
export ZVM_MAN_KEY='K'
# Emacs mode key sequence (default: ^Xk, i.e., Ctrl-X k)
export ZVM_MAN_KEY_EMACS='^X^K'  # Example: Ctrl-X Ctrl-K
# Vi insert mode key (default: ^K, i.e., Ctrl-K)
export ZVM_MAN_KEY_INSERT='^H'   # Example: Ctrl-H
# Enable/disable emacs mode binding (default: true)
export ZVM_MAN_ENABLE_EMACS=false
# Enable/disable vi insert mode binding (default: true)
export ZVM_MAN_ENABLE_INSERT=false
# Use a different pager (default: less)
export ZVM_MAN_PAGER='bat'
### zsh-vi-man
