local opt = vim.opt

-- Gruvbox configurations
if vim.g.gruvbox_contrast_light == nil then
    vim.g.gruvbox_contrast_light = "hard"
end
opt.background = "dark"

-- Ayu Theme configurations
vim.g.ayucolor = "dark"

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
    ["ctrl-y"] = function(lines)
        vim.fn.setreg("*", table.concat(lines, "\n"))
    end
}

-- QuickScope Movement Highlights
vim.g.qs_highlight_on_keys = { "f", "F", "t", "T" }
vim.api.nvim_set_hl(0, "QuickScopePrimary", { underline = true })
vim.api.nvim_set_hl(0, "QuickScopeSecondary", { underline = true })

-- Grepper Global Tools
vim.g.grepper = { tools = { "rg" } }

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

-- Global Spelling Highlighting Overrides
vim.api.nvim_set_hl(0, "SpellBad", { underline = true, fg = "#ff5f5f" })
vim.api.nvim_set_hl(0, "SpellLocal", { underline = true, fg = "#ff5f5f" })
vim.api.nvim_set_hl(0, "SpellRare", { underline = true, fg = "#ff5f5f" })
vim.api.nvim_set_hl(0, "SpellCap", { underline = true, fg = "#ff5f5f" })
