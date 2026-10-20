# ~/.zprofile - Sourced for login shells before .zshrc

# Import systemd environment for SSH sessions
if [[ -v SSH_CLIENT ]]; then
    while IFS= read -r line; do
        [[ -n "$line" ]] && export "$line"
    done < <(systemctl show-environment 2>/dev/null)
fi
