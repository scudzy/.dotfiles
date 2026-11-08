local map = vim.keymap.set
local opts = { noremap = true, silent = true }
local expr_opts = { expr = true, noremap = true, silent = true }

-- Screen line movement adjustments
map({ "n", "v" }, "j", "gj", opts)
map({ "n", "v" }, "k", "gk", opts)
map({ "n", "v" }, "<Down>", "gj", opts)
map({ "n", "v" }, "<Up>", "gk", opts)
map("i", "<Down>", "<C-o>gj", opts)
map("i", "<Up>", "<C-o>gk", opts)

-- Window Pane Navigation
map("n", "<C-l>", "<C-w><C-l>", opts)
map("n", "<C-h>", "<C-w><C-h>", opts)
map("n", "<C-k>", "<C-w><C-k>", opts)
map("n", "<C-j>", "<C-w><C-j>", opts)
map("n", "<S-Tab>", "<C-w>w", opts)

-- Buffer Search & Replace
map("n", "<Leader>r", ":%s///g<Left><Left>", { noremap = true })
map("n", "<Leader>rc", ":%s///gc<Left><Left><Left>", { noremap = true })
map("x", "<Leader>r", ":s///g<Left><Left>", { noremap = true })
map("x", "<Leader>rc", ":s///gc<Left><Left><Left>", { noremap = true })

-- Dynamic Context Replacements
map("n", "s*", [[:let @/='\<'.expand('<cword>').'\>'<CR>cgn]], opts)
map("x", "s*", [["sy:let @/=@s<CR>cgn]], opts)
map({ "n", "v" }, "<Leader><Space>", ":let @/=''<CR>", opts)

-- Text Range Formatting blocks
map("n", "<Leader>g", "gqap", opts)
map("x", "<Leader>g", "gqa", opts)

-- Visual selection protection
map({ "n", "v" }, "x", '"_x', opts)
map({ "n", "v" }, "X", '"_x', opts)
map("x", "p", "pgvy", opts)
map("v", "y", "ygv<Esc>", { noremap = false, silent = true })

-- System File Management Controls
map({ "n", "v" }, "<Leader>ev", ":tabnew $MYVIMRC<CR>", { noremap = false })
map({ "n", "v" }, "<Leader>sv", ":source $MYVIMRC<CR>", { noremap = false })
map({ "n", "v" }, "<F5>", ":setlocal spell!<CR>", { noremap = false })
map({ "n", "v" }, "<F6>", ":set invrelativenumber<CR>", { noremap = false })
map({ "n", "v" }, "<F7>", ":set list!<CR>", { noremap = false })
map("i", "<F7>", "<C-o>:set list!<CR>", { noremap = false })
map("c", "<F7>", "<C-c>:set list!<CR>", { noremap = false })

-- Code Blocks Movement Vectors
map("n", "K", ":m .-2<CR>==", opts)
map("n", "J", ":m .+1<CR>==", opts)
map("v", "K", ":m '<-2<CR>gv=gv", opts)
map("v", "J", ":m '>+1<CR>gv=gv", opts)

-- Spellcheck Correction Return Vector
map("n", "<leader>sp", "mz[s1z=`z", opts)

-- FZF Hotkeys
map("n", "<C-p>", ":FZF -m<CR>", opts)
map("n", "<Leader><Enter>", ":Buffers<CR>", opts)
map("n", "<Leader>l", ":Lines<CR>", opts)

-- Project Wide Search-and-Replace Blocks via Grepper
map("n", "<Leader>R", [[:let @s='\<'.expand('<cword>').'\>'<CR>:Grepper -cword -noprompt<CR>:cfdo %s/<C-r>s//g \| update<Left><Left><Left><Left><Left><Left><Left><Left><Left><Left><Left>]], opts)
map("x", "<Leader>R", [["sygvgr:cfdo %s/<C-r>s//g \| update<Left><Left><Left><Left><Left><Left><Left><Left><Left><Left><Left>]], opts)
map("x", "gr", "<plug>(GrepperOperator)", { noremap = false })

-- Testing Suites Runners
map("n", "t<C-n>", ":TestNearest<CR>", opts)
map("n", "t<C-f>", ":TestFile<CR>", opts)
map("n", "t<C-a>", ":TestSuite<CR>", opts)
map("n", "t<C-l>", ":TestLast<CR>", opts)
map("n", "t<C-v>", ":TestVisit<CR>", opts)

-- PUM Window Selection Navigation Overrides
map("i", "<Down>", [[pumvisible() ? "<C-n>" : "<Down>"]], expr_opts)
map("i", "<Up>", [[pumvisible() ? "<C-p>" : "<Up>"]], expr_opts)
map("i", "<Right>", [[pumvisible() ? "<C-y>" : "<Right>"]], expr_opts)
map("i", "<CR>", [[pumvisible() ? "<C-y>" : "<CR>"]], expr_opts)
map("i", "<Left>", [[pumvisible() ? "<C-e>" : "<Left>"]], expr_opts)

-- Neo-tree File Browser Toggle (Replaced Fern)
map({ "n", "v" }, "<Leader>f", ":Neotree toggle reveal<CR>", opts)

-- Fast Tab Switching and Management Keymaps
local map = vim.keymap.set

-- Open, close, and navigate tabs
map("n", "<leader>to", "<cmd>tabnew<CR>", { desc = "Open new tab" })
map("n", "<leader>tx", "<cmd>tabclose<CR>", { desc = "Close current tab" })

-- Fast tab switching using Shift + H (left) and Shift + L (right)
map("n", "<S-H>", "<cmd>tabprevious<CR>", { desc = "Go to previous tab" })
map("n", "<S-L>", "<cmd>tabnext<CR>", { desc = "Go to next tab" })

-- Jump directly to tabs 1 through 9 using Leader + Number
for i = 1, 9 do
  map("n", "<leader>" .. i, "<cmd>tabnext " .. i .. "<CR>", { desc = "Jump to tab " .. i })
end

-- Interactive Custom User Commands
vim.api.nvim_create_user_command("Rg", function(args)
    vim.fn["fzf#vim#grep"]("rg --column --line-number --no-heading --color=always --smart-case " .. args.args, 1, vim.fn["fzf#vim#with_preview"](), args.bang)
end, { bang = true, nargs = "*" })

vim.api.nvim_create_user_command("Todo", "ProjectTodos", {})
