local g             = vim.g
local cmd           = vim.cmd
local au            = vim.api.nvim_create_autocmd
local validate      = require('validation').validate
local notify_err    = require('error')

local M = {}

function M.ch_highlight(grp, hl)
    local ARGS_SPEC = {
        grp = { type = 'string', required = true },
        hl  = { type = 'table', required = true }
    }
    validate({grp = grp, hl = hl}, ARGS_SPEC)
    local HL_SPEC = {
        fg              = { type = 'string' },
        bg              = { type = 'string' },
        sp              = { type = 'string' },
        blend           = { type = 'number' },
        bold            = { type = 'boolean' },
        standout        = { type = 'boolean' },
        underline       = { type = 'boolean' },
        undercurl       = { type = 'boolean' },
        underdouble     = { type = 'boolean' },
        underdotted     = { type = 'boolean' },
        underdashed     = { type = 'boolean' },
        strikethrough   = { type = 'boolean' },
        italic          = { type = 'boolean' },
        reverse         = { type = 'boolean' },
        nocombine       = { type = 'boolean' },
        link            = { type = 'string' },
        default         = { type = 'boolean' },
        ctermfg         = { type = 'string' },
        ctermbg         = { type = 'string' },
        cterm           = { type = 'string' },
    }
    validate(hl, HL_SPEC)

    local newhl = vim.api.nvim_get_hl_by_name(grp, true)
    for k,v in pairs(hl) do
        newhl[k] = v
    end

    xpcall(vim.api.nvim_set_hl, function(msg)
        notify_err('color', msg)
    end, 0, grp, newhl)
end

-- options:
--
-- background       - 'dark' or 'light'
function M.colorscheme(name, options, after)
    cmd('colorscheme '.. name)

    if after and type(after) == 'function' then
        after()
    end
end

return M
