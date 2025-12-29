# Improved z.lua + fzf integration
z() {
    if [ $# -gt 0 ]; then
        _z "$*"
    else
        local dir
        dir=$(_z -l 2>&1 | fzf --height 40% --nth 2.. --reverse --inline-info +s --tac | sed 's/^[0-9,.]* *//')
        [ -n "$dir" ] && cd "$dir"
    fi
}