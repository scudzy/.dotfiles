-- Global variables (Leader keys must be set BEFORE plugins/mappings)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Global Editor Options
local opt = vim.opt
local state_dir = vim.fn.stdpath("state")
local backup_dir = state_dir .. "/backup"
local swap_dir = state_dir .. "/swap"
local undo_dir = state_dir .. "/undo"

for _, dir in ipairs({ backup_dir, swap_dir, undo_dir }) do
  vim.fn.mkdir(dir, "p")
end

opt.autoindent = true
opt.autoread = true
opt.backspace = { "indent", "eol", "start" }
opt.backupdir = { backup_dir .. "//" }
opt.clipboard = "unnamedplus" -- Zero startup lag in Neovim!
opt.colorcolumn = "80"
opt.complete:append("kspell")
opt.completeopt = { "menuone", "longest" }
opt.cursorline = true
opt.directory = { swap_dir .. "//" }
opt.encoding = "utf-8"
opt.expandtab = true
opt.smarttab = true
opt.formatoptions = "tcqrn1"
opt.hidden = true
opt.hlsearch = true
opt.ignorecase = true
opt.incsearch = true
opt.laststatus = 2
opt.matchpairs:append("<:>")
opt.mmp = 5000
opt.modelines = 2
opt.mouse = "a"
opt.visualbell = true
opt.shiftround = false
opt.spell = false
opt.startofline = false
opt.number = true
opt.relativenumber = true
opt.regexpengine = 1
opt.ruler = true
opt.scrolloff = 3
opt.shiftwidth = 4
opt.showcmd = true
opt.showmatch = true
opt.shortmess:append("c")
opt.showmode = false -- Turned off globally since you use Lualine
opt.smartcase = true
opt.softtabstop = 2
opt.spelllang = { "en_us" }
opt.splitbelow = true
opt.splitright = true
opt.tabstop = 4
opt.textwidth = 0
opt.timeoutlen = 1000
opt.undodir = undo_dir
opt.undofile = true
opt.virtualedit = "block"
opt.whichwrap = "b,s,<,>"
opt.wildmenu = true
opt.wildmode = "full"
opt.wrap = true

-- Truecolor support configuration (Native in modern Neovim)
opt.termguicolors = true

-- Runtime overrides
vim.cmd("runtime! macros/matchit.vim")
opt.omnifunc = "syntaxcomplete#Complete"
opt.rtp:prepend("/usr/share/vimpager")
