-- Entry point: Load all configuration modules sequentially
require("options")
require("plugins")
require("plugin_settings")
require("keymaps")
require("autocmds")

-- Enable virtual line wrapping
vim.opt.wrap = true

-- Constrain the visual wrap width to 80 columns
vim.opt.wrapmargin = 80

-- Optional: Wrap at words rather than breaking mid-word
vim.opt.linebreak = true

-- Sync system clipboard
vim.opt.clipboard = "unnamedplus"

-- highlightedyank
vim.api.nvim_create_autocmd("TextYankPost", {
    callback = function() vim.highlight.on_yank({ timeout = 200 }) end,
})

-- Apply strict 80-character hard wrapping only to text-heavy files
vim.api.nvim_create_autocmd("FileType", {
    pattern = { "markdown", "text", "gitcommit", "mail" },
    callback = function()
        vim.opt_local.textwidth = 80
        vim.opt_local.colorcolumn = "80"
    end,
})
