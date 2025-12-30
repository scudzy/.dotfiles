
# dotfiles 

My personal dotfiles configuration for Windows 11 with WSL2.


### Debian
```
Debian GNU/Linux 
VERSION_CODENAME=trixie
DEBIAN_VERSION_FULL=13.2
```

#### What's Included

- Zsh Configuration - Custom .zshrc with optimized settings and plugins
- [Zinit Plugin Manager](https://github.com/zdharma-continuum/zinit) - Lightweight plugin and application installer with lazy-loading and turbo mode for fast shell startup
- Editor Config - vim/neovim, VS Code, and other editor configurations
- Git Configuration - Git aliases and workflow setup
- Terminal/Prompt Setup - Custom prompt styling and terminal utilities
- Application Automation - Zinit-managed CLI tools and system utilities

#### About Zinit

This setup uses **Zinit** for plugin and application management. Zinit is a lightweight, fast plugin manager for Zsh that supports:

- **Lazy-loading** - Load plugins only when needed
- **Turbo mode** - Background loading for instant shell startup
- **Binary installation** - Install and manage CLI tools alongside plugins
- **Advanced compilation** - Pre-compile plugins for faster execution

Zinit keeps your shell startup fast while providing a powerful plugin ecosystem.
### Structure

#### Directory Structure

```
~/.dotfiles/
├── zsh/            # Zsh configuration (.zshrc, Zinit setup)
├── zinit/          # Zinit plugin and app installations
├── git/            # Git configuration
├── tmux/           # tmux plugins & settings
├── vim/            # vim plugins & color scheme
├── etc/            # wsl config files
├── sh/             # Helper scripts and utilities
└── install.sh      # Installation script
```

#### System Requirements

- Windows 11
- WSL2 (Ubuntu/Debian)
- Git
## Quick start

Clone and install:

```bash
git clone https://gitlab.com/scudzy/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh  # adjust as needed
```
#### Installation

- *Install Plug (Vim plugin manager).*
```sh
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
```

- *Install TPM (Tmux plugin manager).*
```sh
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

- *Install plugins for Vim*
Open Vim and install the configured plugins. You would type in the **:PlugInstall** command from within Vim and then hit enter to issue the command.
```sh
vim .
:PlugInstall
```

- *Install tmux plugin*
Start a tmux session and install the configured plugins. You would type in ` followed by I (capital i) to issue the command.
```sh
tmux
`I
```

### Badges

[![Logo](https://img.shields.io/badge/gitlab-repo-blue?logo=gitlab)](https://gitlab.com/scudzy/dotfiles-wsl.git)
[![Logo](https://img.shields.io/badge/github-repo-blue?logo=github)](https://github.com/scudzy/dotfiles-wsl.git)


[![MIT License](https://img.shields.io/badge/License-MIT-green.svg)](https://choosealicense.com/licenses/mit/)


### Notes

- These are personal configs; adjust paths/settings for your setup
- Backup your existing dotfiles before running install script
- [Add any other relevant notes]

## Authors

- [@scudzy](https://www.github.com/scudzy)    


