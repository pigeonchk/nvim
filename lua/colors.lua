local g = vim.g
local cmd = vim.cmd
local au = vim.api.nvim_create_autocmd

local custom_highlight_grpid = vim.api.nvim_create_augroup('custom_highlight', {clear = false})

local M = {}

function M.custom_highlight(hi)
    local hi_str
    if type(hi) == 'table' then
        hi_str = table.concat(hi, ' ')
    end
    local command = 'highlight ' .. hi_str or hi
    au('ColorScheme', {pattern='*', command=command, group=custom_highlight_grpid})
end

function M.colorscheme(name, setup, after)
    if setup and type(setup) == 'function' then
        setup()
    end

    cmd('colorscheme '.. name)

    if after and type(after) == 'function' then
        after()
    end
end

return M
