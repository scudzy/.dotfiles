-- lua/plugins.lua

-- Define Neovim's native data paths
local data_dir = vim.fn.stdpath('data') .. '/site'
local plug_path = data_dir .. '/autoload/plug.vim'

-- Auto-download vim-plug if it doesn't exist
if vim.fn.empty(vim.fn.glob(plug_path)) > 0 then
    print('Downloading vim-plug for Neovim...')
    vim.fn.system({'curl', '-fLo', plug_path, '--create-dirs', 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'})

    -- FORCE Neovim to register the new path immediately in this session
    vim.opt.rtp:prepend(data_dir)

    -- Trigger the installation on boot cleanly
    vim.cmd('autocmd VimEnter * PlugInstall --sync | source ' .. vim.fn.stdpath('config') .. '/init.lua')
else
    -- Ensure Neovim explicitly knows where to look even on standard boots
    vim.opt.rtp:prepend(data_dir)
end

-- Wrap the vim-plug initialization block inside a raw Vimscript evaluation block
-- This bypasses early runtime path lookup errors during the Lua boot phase.

vim.cmd([[
call plug#begin(stdpath('data') .. '/plugged')

" Theme Profiles
Plug 'rakr/vim-one'
Plug 'joshdick/onedark.vim'
Plug 'tribela/vim-transparent'
Plug 'gruvbox-community/gruvbox'
Plug 'jacoborus/tender.vim'
Plug 'ayu-theme/ayu-vim'
Plug 'dracula/vim', { 'as': 'dracula' }

" Navigation / Searching
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'lambdalisue/fern.vim'
Plug 'lambdalisue/fern-mapping-mark-children.vim'
Plug 'lambdalisue/vim-fern-renderer-nerdfont'
Plug 'lambdalisue/vim-glyph-palette'
Plug 'unblevable/quick-scope'
Plug 'mhinz/vim-grepper'

" System Utilities / Integration
Plug 'tpope/vim-obsession'
Plug 'dhruvasagar/vim-zoom'
Plug 'tmux-plugins/vim-tmux-focus-events'
Plug 'tpope/vim-eunuch'
Plug 'will133/vim-dirdiff'
Plug 'AndrewRadev/linediff.vim'
Plug 'inkarkat/vim-ingo-library'
Plug 'inkarkat/vim-SpellCheck'
Plug 'machakann/vim-highlightedyank'
Plug 'nelstrom/vim-visual-star-search'
Plug 'haya14busa/is.vim'
Plug 'ntpeters/vim-better-whitespace'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-sleuth'
Plug 'tpope/vim-unimpaired'
Plug 'Konfekt/FastFold'
Plug 'mhinz/vim-signify'
Plug 'tpope/vim-fugitive'
Plug 'junegunn/limelight.vim'
Plug 'junegunn/goyo.vim'
Plug 'SirVer/ultisnips' | Plug 'honza/vim-snippets'
Plug 'vim-scripts/AutoComplPop'
Plug 'janko/vim-test'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'editorconfig/editorconfig-vim'
Plug 'ervandew/supertab'
Plug 'easymotion/vim-easymotion'
Plug 'junegunn/vim-easy-align'
Plug 'jasonccox/vim-wayland-clipboard'
Plug 'alker0/chezmoi.vim'
Plug 'petRUShka/vim-sage'
Plug 'imsnif/kdl.vim'
Plug 'dstein64/vim-startuptime'

" Languages and File Types
Plug 'cakebaker/scss-syntax.vim'
Plug 'chr4/nginx.vim'
Plug 'chrisbra/csv.vim'
Plug 'ekalinin/dockerfile.vim'
Plug 'elixir-editors/vim-elixir'
Plug 'Glench/Vim-Jinja2-Syntax'
Plug 'godlygeek/tabular' | Plug 'tpope/vim-markdown'
Plug 'iamcco/markdown-preview.nvim', { 'do': 'cd app & yarn install' }
Plug 'jvirtanen/vim-hcl'
Plug 'lifepillar/pgsql.vim'
Plug 'othree/html5.vim'
Plug 'pangloss/vim-javascript'
Plug 'PotatoesMaster/i3-vim-syntax'
Plug 'stephpy/vim-yaml'
Plug 'tmux-plugins/vim-tmux'
Plug 'tpope/vim-git'
Plug 'tpope/vim-liquid'
Plug 'tpope/vim-rails'
Plug 'vim-python/python-syntax'
Plug 'vim-ruby/vim-ruby'
Plug 'wgwoods/vim-systemd-syntax'
Plug 'zdharma-continuum/zinit-vim-syntax'
Plug 'groenewege/vim-less'

call plug#end()
]])
