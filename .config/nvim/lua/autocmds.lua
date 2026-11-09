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

-- Keep the cursorline visible only in the active window.
autocmd({ "VimEnter", "WinEnter", "BufWinEnter" }, {
    group = cursor_line_group,
    pattern = "*",
    command = "setlocal cursorline",
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
    if vim.fn.executable("rg") ~= 1 then
        vim.notify("ProjectTodos requires ripgrep (rg)", vim.log.levels.ERROR)
        return
    end

    local output = vim.fn.systemlist({
        "rg",
        "--line-number",
        "--no-heading",
        "--color=never",
        "--word-regexp",
        "-e", "TODO",
        "-e", "FIXME",
        ".",
    })
    local status = vim.v.shell_error
    if status > 1 then
        vim.notify("ProjectTodos search failed:\n" .. table.concat(output, "\n"), vim.log.levels.ERROR)
        return
    end

    local entries = {}
    for _, line in ipairs(output) do
        local fname, lno, text = line:match("^(.*):(%d+):(.*)$")
        if fname then
            table.insert(entries, { filename = fname, lnum = tonumber(lno), text = text })
        end
    end

    if #entries > 0 then
        vim.fn.setqflist({}, " ", { title = "Project TODOs", items = entries })
        vim.cmd("copen")
    else
        vim.notify("No TODO or FIXME markers found", vim.log.levels.INFO)
    end
end, {})
