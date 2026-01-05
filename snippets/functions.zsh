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

### Function for pkglist
pkglist() { apt list "$1"* 2>/dev/null | rg -n --no-heading --color=always "${2:-^$1}"; }

### passmenu
# WSL2 optimized passmenu using Rofi
passmenu() {
  local selection
  # Added -m -2 to follow mouse to your 24" monitor
  # Added -i for case-insensitive search
  selection=$(find ~/.password-store -name "*.gpg" | sed "s|$HOME/.password-store/||;s|\.gpg$||" | \
              GDK_BACKEND=x11 rofi -dmenu -i -p "Pass" -m -2 -no-grab -normal-window 2>/dev/null)

  if [[ -n "$selection" ]]; then
      pass show -c "$selection"
      # Windows-native popup so it shows up in the Windows taskbar
      powershell.exe -Command "Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show('Copied $selection', 'Passmenu')" &
      # powershell -Command "Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show('Password for $selection copied.', 'Passmenu')" &
  fi
}
