local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- Setup Group Namespaces
local general_group = augroup("GeneralAutoCommands", { clear = true })
local cursor_line_group = augroup("CursorLineToggle", { clear = true })

-- Structural Window Event Auto-resizing
autocmd("VimResized", {
    group = general_group,
    pattern = "*",
    command = "wincmd =",
})

-- External File Modification Synchronization
autocmd({ "FocusGained", "BufEnter" }, {
    group = general_group,
    pattern = "*",
    command = "checktime",
})

-- Reset insert state options safely on leave
autocmd("InsertLeave", {
    group = general_group,
    pattern = "*",
    command = "silent! set nopaste",
})

-- Custom Filetype Injection Patterns
autocmd({ "BufNewFile", "BufRead" }, {
    group = general_group,
    pattern = "requirements*.txt",
    command = "set ft=python",
})

autocmd({ "BufNewFile", "BufRead" }, {
    group = general_group,
    pattern = ".*aliases",
    command = "set ft=sh",
})

autocmd("FileType", {
    group = general_group,
    pattern = "make",
    command = "setlocal noexpandtab",
})

-- Contextual CursorLine visibility toggles
autocmd({ "VimEnter", "WinEnter", "BufWinEnter" }, {
    group = cursor_line_group,
    pattern = "*",
    command = "setlocal nocursorline",
})

autocmd("WinLeave", {
    group = cursor_line_group,
    pattern = "*",
    command = "setlocal nocursorline",
})

-- Presentation Mode Trigger (.vpm files)
autocmd({ "BufNewFile", "BufRead" }, {
    group = general_group,
    pattern = "*.vpm",
    callback = function()
        -- Map arrow keys for presentation navigation and launch Goyo focus mode
        vim.keymap.set("n", "<Right>", ":n<CR>", { buffer = true })
        vim.keymap.set("n", "<Left>", ":N<CR>", { buffer = true })
        if vim.fn.exists("#goyo") == 0 then
            vim.cmd("Goyo")
        end
    end,
})

-- Helper Command: Legacy Quickfix View Toggle
vim.api.nvim_create_user_command("QuickFixToggle", function()
    for i = 1, vim.fn.winnr("$") do
        local bnum = vim.fn.winbufnr(i)
        if vim.fn.getbufvar(bnum, "&buftype") == "quickfix" then
            vim.cmd("cclose")
            return
        end
    end
    vim.cmd("copen")
end, {})

-- Helper Command: Project Todo Compilation Pipeline
vim.api.nvim_create_user_command("ProjectTodos", function()
    local entries = {}
    local cmds = {
        "git grep -niIw -e TODO -e FIXME 2> /dev/null",
        "grep -rniIw -e TODO -e FIXME . 2> /dev/null"
    }
    for _, cmd in ipairs(cmds) do
        local handle = io.popen(cmd)
        if handle then
            local result = handle:read("*a")
            handle:close()
            if result ~= "" then
                for line in result:gmatch("[^\r\n]+") do
                    local fname, lno, text = line:match("^([^:]*):([^:]*):(.*)")
                    if fname and lno and text then
                        table.insert(entries, { filename = fname, lnum = tonumber(lno), text = text })
                    end
                end
                break
            end
        end
    end
    if #entries > 0 then
        vim.fn.setqflist(entries)
        vim.cmd("copen")
    end
end, {})
