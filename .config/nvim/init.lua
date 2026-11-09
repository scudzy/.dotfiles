-- 1. Load core editor options first
require("options")

-- 2. Load automated event rules and keymaps
require("autocmds")
require("keymaps")

-- Neovide graphical interface settings
vim.g.neovide_progress_bar_enabled = true
vim.g.neovide_progress_bar_height = 5.0
vim.g.neovide_progress_bar_animation_speed = 200.0
vim.g.neovide_progress_bar_hide_delay = 0.2
vim.g.neovide_hide_mouse_when_typing = false
vim.g.neovide_remember_window_size = true

-- Dev provider
vim.g.loaded_node_provider = 0
--vim.g.node_host_prog = '/usr/bin/node'
vim.g.loaded_perl_provider = 0
local python3_host = vim.env.NVIM_PYTHON3_HOST_PROG or vim.fn.exepath("python3")
if python3_host ~= "" then
  vim.g.python3_host_prog = python3_host
else
  vim.g.loaded_python3_provider = 0
end
vim.g.loaded_ruby_provider = 0

-- 3. Bootstrap lazy.nvim plugin manager
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  if vim.fn.executable("git") ~= 1 then
    error("lazy.nvim is not installed and Git is unavailable; install Git and restart Neovim")
  end
  vim.fn.mkdir(vim.fn.fnamemodify(lazypath, ":h"), "p")
  local output = vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
  if vim.v.shell_error ~= 0 or not vim.loop.fs_stat(lazypath) then
    error("Failed to install lazy.nvim:\n" .. output)
  end
end
vim.opt.rtp:prepend(lazypath)

-- 4. Setup plugins and dependencies
require("lazy").setup({
  -- Theme Profiles
  { "rakr/vim-one" },
  { "folke/tokyonight.nvim" },
  { "joshdick/onedark.vim" },
  { "tribela/vim-transparent" },
  { "gruvbox-community/gruvbox" },
  { "jacoborus/tender.vim" },
  {
    "ayu-theme/ayu-vim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.g.ayucolor = "dark"
      vim.cmd("colorscheme ayu")
    end,
  },
  { "dracula/vim", name = "dracula" },

  -- Navigation / Searching (Lazy-loaded on commands)
  {
    "junegunn/fzf.vim",
    dependencies = { { "junegunn/fzf", build = "./install --bin" } },
    cmd = { "FZF", "Buffers", "Lines", "Rg" },
    init = function()
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
    end,
  },
  { "unblevable/quick-scope" },
  {
    "mhinz/vim-grepper",
    cmd = { "Grepper" },
    keys = { "gr", "<Leader>R" },
    init = function()
      vim.g.grepper = { tools = { "rg" } }
    end,
  },

  -- System Utilities & Integrations
  { "tpope/vim-obsession" },
  { "dhruvasagar/vim-zoom" },
  { "tpope/vim-eunuch" },
  { "will133/vim-dirdiff" },
  { "AndrewRadev/linediff.vim" },
  { "inkarkat/vim-ingo-library" },
  { "tpope/vim-sleuth" },
  { "tpope/vim-unimpaired" },
  { "mhinz/vim-signify" },
  { "tpope/vim-fugitive" },
  {
    "junegunn/limelight.vim",
    init = function()
      vim.g.limelight_conceal_ctermfg = 244
    end,
  },
  { "junegunn/goyo.vim" },

  -- Snippet Engine (Lazy-loaded on insert mode entry)
  {
    "SirVer/ultisnips",
    dependencies = { "honza/vim-snippets" },
    event = "InsertEnter",
    init = function()
      vim.g.UltiSnipsJumpForwardTrigger = "<tab>"
      vim.g.UltiSnipsJumpBackwardTrigger = "<s-tab>"
    end,
  },

  { "janko/vim-test" },
  { "ervandew/supertab" },
  { "easymotion/vim-easymotion" },
  { "junegunn/vim-easy-align" },
  { "petRUShka/vim-sage" },
  { "imsnif/kdl.vim" },

  -- Modern Status Bar (Lualine)
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup({ options = { theme = "ayu" } })
    end,
  },

  -- Non-Native Languages and File Types
  { "chrisbra/csv.vim" },
  { "elixir-editors/vim-elixir" },
  { "Glench/Vim-Jinja2-Syntax" },
  { "godlygeek/tabular", dependencies = { "tpope/vim-markdown" } },
  {
    "iamcco/markdown-preview.nvim",
    build = "cd app && yarn install",
    cmd = { "MarkdownPreview", "MarkdownPreviewStop", "MarkdownPreviewToggle" },
  },
  { "jvirtanen/vim-hcl" },
  { "PotatoesMaster/i3-vim-syntax" },
  { "tpope/vim-liquid" },
  { "tpope/vim-rails" },
  { "zdharma-continuum/zinit-vim-syntax" },

  -- Modern File Tree Explorer (Neo-tree - Lazy-loaded on command or keymap)
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    cmd = "Neotree",
    keys = {
      { "<leader>f", ":Neotree toggle reveal<CR>", desc = "Toggle Neo-tree" },
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    config = function()
      require("neo-tree").setup({})
    end,
  },
})

-- 5. Load plugin specific options and overrides after plugins load
require("plugin_settings")
