-- vim:foldmethod=marker:foldlevel=0

local validate  = require('validation').validate
local notify_err = require('error')

local cmd = vim.cmd

local M = {}

-- highlight {{{1
--[[
--  Call the :highlight command.
--
--  The argument can be both a list or a string.
--]]
function M.highlight(hi)
    local hi_str
    if type(hi) == 'table' then
        hi_str = table.concat(hi, ' ')
    end
    cmd('highlight ' .. hi_str or hi)
end
-- 1}}}

-- abbrev {{{1
--[[
--  creates a insert mode abbreviation.
--]]
function M.iabbrev(_abbrev)
    local abbrev = _abbrev
    if type(_abbrev) == 'table' then
        abbrev = table.concat(_abbrev, ' ')
    end

    cmd('iabbrev '.. abbrev)
end
-- 1}}}

-- mappings {{{1
local map = vim.keymap.set

function M.map(lhs, rhs, _opts, _mode, noremap)
    local mode = _mode or ''

    opts = _opts or {}
    if noremap then
        opts.noremap = true
    end
    map(mode, lhs, rhs, opts)
end

-- normal mode {{{2
function M.noremap(lhs, rhs, opts)
    M.map(lhs, rhs, opts, '', true)
end

function M.nmap(lhs, rhs, opts)
    M.map(lhs, rhs, opts, 'n')
end

function M.nnoremap(lhs, rhs, opts)
    M.map(lhs, rhs, opts, 'n', true)
end
-- 2}}}

-- insert mode {{{2

function M.imap(lhs, rhs, opts)
    M.map(lhs, rhs, opts, 'i')
end

function M.inoremap(lhs, rhs, opts)
    M.map(lhs, rhs, opts, 'i', true)
end
-- 2}}}

-- visual mode {{{2
function M.vmap(lhs, rhs, opts)
    M.map(lhs, rhs, opts, 'v')
end

function M.vnoremap(lhs, rhs, opts)
    M.map(lhs, rhs, opts, 'v', true)
end
-- 2}}}

-- terminal mode {{{2
function M.tmap(lhs, rhs, opts)
    M.map(lhs, rhs, opts, 't')
end

function M.tnoremap(lhs, rhs, opts)
    M.map(lhs, rhs, opts, 't', true)
end
-- 2}}}

-- 1}}}

M.buf_get_var = function(buf, var)
    local SPEC = {
        buf = {type = 'number', required = true},
        var = {type = 'string', required = true},
    }

    if not validate({buf = buf, var = var}, SPEC) then
        return nil
    end

    local ok, val = pcall(vim.api.nvim_get_var, buf, var)

    if ok then
        return val
    end

    return nil
end

M.buf_set_var = function(buf, var, val)
    local SPEC = {
        buf = {type = 'number', required = true},
        var = {type = 'string', required = true},
    }

    if not validate({buf = buf, var = var}, SPEC) then
        return
    end

    if not val then
        notify_err('viml', 'val is required for viml.buf_set_var()')
        return
    end

    return pcall(vim.api.nvim_get_var, buf, var)
end

return M
