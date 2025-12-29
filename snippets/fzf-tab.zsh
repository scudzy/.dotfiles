zstyle ':completion:*' verbose yes
zstyle ':completion:*' list-colors \${(s.:.)LS_COLORS}
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion::complete:*:*:files' ignored-patterns '.DS_Store' 'Icon?' '.Trash'
zstyle ':completion::complete:*:*:globbed-files' ignored-patterns '.DS_Store' 'Icon?' '.Trash'
zstyle ':completion::complete:rm:*:globbed-files' ignored-patterns
zstyle ':fzf-tab:*' fzf-command fzf
zstyle ':fzf-tab:*' fzf-flags '--ansi'
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'exa -1 --color=always $realpath'
zstyle ':fzf-tab:complete:_zlua:*' query-string input
zstyle ':fzf-tab:complete:systemctl-*:*' fzf-preview 'SYSTEMD_COLORS=1 systemctl status $word'
zstyle ':fzf-tab:*' fzf-bindings \
  'tab:accept' \
  'ctrl-y:preview-page-up' \
  'ctrl-v:preview-page-down' \
  'ctrl-e:execute-silent(\${VISUAL:-code} \$realpath >/dev/null 2>&1)' \
  'ctrl-w:execute(\${EDITOR:-nano} \$realpath >/dev/tty </dev/tty)+refresh-preview'
zstyle ':fzf-tab:*' fzf-min-height 15
zstyle ':fzf-tab:complete:git-(add|diff|restore):*' fzf-preview \
  'git diff --no-ext-diff \$word | delta --paging=never --no-gitconfig --line-numbers --file-style=omit --hunk-header-style=omit --theme=base16'
zstyle ':fzf-tab:complete:git-log:*' fzf-preview \
  'git --no-pager log --color=always --format=oneline --abbrev-commit --follow \$word'
zstyle ':fzf-tab:complete:man:*' fzf-preview \
  'man -P \"col -bx\" \$word | $FZF_PREVIEW_FILE_COMMAND --language=man'
zstyle ':fzf-tab:complete:brew-(install|uninstall|search|info):*-argument-rest' fzf-preview \
  'brew info \$word'
zstyle ':fzf-tab:complete:(-command-|-parameter-|-brace-parameter-|export|unset|expand):*' fzf-preview \
  'echo \${(P)word}'
zstyle ':fzf-tab:complete:*:options' fzf-preview
zstyle ':fzf-tab:complete:*:options' fzf-flags '--no-preview'
zstyle ':fzf-tab:complete:*:argument-1' fzf-preview
zstyle ':fzf-tab:complete:*:argument-1' fzf-flags '--no-preview'
zstyle ':fzf-tab:complete:*:*' fzf-preview \
  '($FZF_PREVIEW_FILE_COMMAND \$realpath || $FZF_PREVIEW_DIR_COMMAND \$realpath) 2>/dev/null'