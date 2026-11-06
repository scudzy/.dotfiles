local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup

-- Setup Group Namespaces
local general_group = augroup("GeneralAutoCommands", { clear = true })
local cursor_line_group = augroup("CursorLineToggle", { clear = true })
local fern_group = augroup("FernIntegration", { clear = true })

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
    command = "setlocal cursorline",
})

autocmd("WinLeave", {
    group = cursor_line_group,
    pattern = "*",
    command = "setlocal nocourse_line",
})

-- Directory Hijacking and File Manager Hooks
autocmd("BufEnter", {
    group = fern_group,
    pattern = "*",
    nested = true,
    callback = function()
        local path = vim.fn.expand("%:p")
        if vim.fn.isdirectory(path) == 0 then return end
        vim.cmd("bwipeout %")
        vim.cmd(string.format("Fern %s", vim.fn.fnameescape(path)))
    end,
})

autocmd("FileType", {
    group = fern_group,
    pattern = "fern",
    callback = function()
        vim.cmd("call FernInit()")
    end,
})

autocmd("FileType", {
    group = fern_group,
    pattern = { "fern", "nerdtree", "startify" },
    callback = function()
        vim.fn["glyph_palette#apply"]()
    end,
})

autocmd({ "BufNewFile", "BufRead" }, {
    group = general_group,
    pattern = "*.vpm",
    callback = function()
        vim.cmd("call SetVimPresentationMode()")
    end,
})

vim.cmd([[
    " Legacy Quickfix View Toggle Routine
    function! QuickFix_toggle()
        for i in range(1, winnr('$'))
            let bnum = winbufnr(i)
            if getbufvar(bnum, '&buftype') == 'quickfix'
                cclose
                return
            endif
        endfor
        copen
    endfunction

    " Project Todo Compilation Pipeline
    function! s:todo() abort
        let entries = []
        for cmd in ['git grep -niIw -e TODO -e FIXME 2> /dev/null', 'grep -rniIw -e TODO -e FIXME . 2> /dev/null']
            let lines = split(system(cmd), '\n')
            if v:shell_error != 0 | continue | endif
            for line in lines
                let [fname, lno, text] = matchlist(line, '^\([^:]*\):\([^:]*\):\(.*\)')[1:3]
                call add(entries, { 'filename': fname, 'lnum': lno, 'text': text })
            endfor
            break
        endfor
        if !empty(entries)
            call setqflist(entries)
            copen
        endif
    endfunction

    " Direct Engine Profiling Engine
    function! s:profile(bang)
        if a:bang
            profile pause
            noautocmd qall
        else
            profile start /tmp/profile.log
            profile func *
            profile file *
        endif
    endfunction

    " Presentation Mode Interface Modification Function
    function SetVimPresentationMode()
        nnoremap <buffer> <Right> :n<CR>
        nnoremap <buffer> <Left> :N<CR>
        if !exists('#goyo')
            Goyo
        endif
    endfunction

    " Legacy Mapping Functions Setup
    function FernInit() abort
        nmap <buffer><expr> <Plug>(fern-my-open-expand-collapse) fern#smart#leaf("\<Plug>(fern-action-open:select)", "\<Plug>(fern-action-expand)", "\<Plug>(fern-action-collapse)")
        nmap <buffer> <CR> <Plug>(fern-my-open-expand-collapse)
        nmap <buffer> <2-LeftMouse> <Plug>(fern-my-open-expand-collapse)
        nmap <buffer> n <Plug>(fern-action-new-path)
        nmap <buffer> d <Plug>(fern-action-remove)
        nmap <buffer> m <Plug>(fern-action-move)
        nmap <buffer> M <Plug>(fern-action-rename)
        nmap <buffer> h <Plug>(fern-action-hidden-toggle)
        nmap <buffer> r <Plug>(fern-action-reload)
        nmap <buffer> k <Plug>(fern-action-mark)
        nmap <buffer> K <Plug>(fern-action-mark-children:leaf)
        nmap <buffer> b <Plug>(fern-action-open:split)
        nmap <buffer> v <Plug>(fern-action-open:vsplit)
        nmap <buffer><nowait> < <Plug>(fern-action-leave)
        nmap <buffer><nowait> > <Plug>(fern-action-enter)
    endfunction
]])
