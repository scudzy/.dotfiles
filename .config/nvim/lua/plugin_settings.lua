-- Filetype indent & syntax (handled implicitly by Neovim, but kept for rigidity)
vim.cmd("filetype plugin indent on")
vim.cmd("syntax on")

-- Gruvbox configurations
if vim.g.gruvbox_contrast_light == nil then
    vim.g.gruvbox_contrast_light = "hard"
end
vim.opt.background = "dark"

-- Ayu Theme configurations
vim.g.ayucolor = "dark"
vim.g.airline_theme = "ayu"
vim.g.airline_powerline_fonts = 1
vim.cmd("colorscheme ayu")

-- Airline Layout Settings
vim.g["airline#extensions#tabline#enabled"] = 1
vim.g["airline#extensions#tabline#left_sep"] = " "
vim.g["airline#extensions#tabline#left_alt_sep"] = "|"
vim.g["airline#extensions#tabline#formatter"] = "default"
vim.opt.showtabline = 2

-- FZF Engine Options
vim.env.FZF_DEFAULT_OPTS = "--bind ctrl-a:select-all"
vim.g.fzf_colors = {
    fg = { "fg", "Normal" },
    bg = { "bg", "Normal" },
    hl = { "fg", "Comment" },
    ["fg+"] = { "fg", "CursorLine", "CursorColumn", "Normal" },
    ["bg+"] = { "bg", "CursorLine", "CursorColumn" },
    ["hl+"] = { "fg", "Statement" },
    info = { "fg", "PreProc" },
    prompt = { "fg", "Conditional" },
    pointer = { "fg", "Exception" },
    marker = { "fg", "Keyword" },
    spinner = { "fg", "Label" },
    header = { "fg", "Comment" }
}
vim.g.fzf_action = {
    ["ctrl-t"] = "tab split",
    ["ctrl-b"] = "split",
    ["ctrl-v"] = "vsplit",
    ["ctrl-y"] = "function(lines) vim.fn.setreg('*', table.concat(lines, '\\n')) end"
}

-- Fern Tree View settings
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.g.loaded_netrwSettings = 1
vim.g.loaded_netrwFileHandlers = 1
vim.g.fern_disable_startup_warnings = 1
vim.g["nerdfont#autofix_cellwidths"] = 1
vim.g["nerdfont#directory#customs"] = { open = "", close = "" }

-- QuickScope Movement Highlights
vim.g.qs_highlight_on_keys = { "f", "F", "t", "T" }
vim.cmd([[
    highlight QuickScopePrimary gui=underline cterm=underline
    highlight QuickScopeSecondary gui=underline cterm=underline
]])

-- Grepper Global Tools
vim.g.grepper = { tools = { "rg" } }

-- Whitespace/Formatting Behaviors
vim.g.strip_whitespace_confirm = 0
vim.g.strip_whitelines_at_eof = 1
vim.g.strip_whitespace_on_save = 1
vim.g.indentLine_char = ""
vim.g.indentLine_first_char = ""
vim.g.indentLine_showFirstIndentLevel = 1
vim.g.indentLine_setColors = 0

-- FastFold Options
vim.g.fastfold_savehook = 0
vim.g.fastfold_fold_command_suffixes = {}

-- Limelight Contrast
vim.g.limelight_conceal_ctermfg = 244

-- Markdown Preview Executables
vim.g.mkdp_auto_close = 0
vim.g.mkdp_refresh_slow = 1
vim.g.mkdp_markdown_css = vim.fn.fnameescape(vim.env.HOME) .. "/.local/lib/github-markdown-css/github-markdown.css"

-- UltiSnips Controls
vim.g.UltiSnipsJumpForwardTrigger = "<tab>"
vim.g.UltiSnipsJumpBackwardTrigger = "<s-tab>"

-- Automated Language Test Execution Vectors
vim.g["test#strategy"] = "neovim"
vim.g["test#python#pytest#executable"] = "docker-compose exec web py.test"
vim.g["test#ruby#rails#executable"] = "docker-compose exec -e RAILS_ENV=test webpacker rails test"
vim.g["test#elixir#exunit#executable"] = "docker-compose exec -e MIX_ENV=test web mix test"
vim.g["vim_tmux_clipboard#loadb_option"] = "-w"

-- Global Highlighting Overrides
vim.cmd([[
    hi SpellBad cterm=underline ctermfg=203 guifg=#ff5f5f
    hi SpellLocal cterm=underline ctermfg=203 guifg=#ff5f5f
    hi SpellRare cterm=underline ctermfg=203 guifg=#ff5f5f
    hi SpellCap cterm=underline ctermfg=203 guifg=#ff5f5f
]])
