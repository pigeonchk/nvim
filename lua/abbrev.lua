local iabbrev = require('viml').iabbrev
local inoremap = require('viml').inoremap

local eat_all_chars = '<C-R>=v:lua.require("abbrev")._eatchar(".")<CR>'

iabbrev {'<silent>', '#!', '#!/usr/bin/'.. eat_all_chars}
iabbrev {'<silent>', '(', '()<left>'..eat_all_chars}
iabbrev {'<silent>', '{', '{}<left>'..eat_all_chars}
iabbrev {'<silent>', '[', '[]<left>'..eat_all_chars}
iabbrev {'<silent>', '<>', '<><left>'..eat_all_chars}
iabbrev {'<silent>', '"', '""<left>'..eat_all_chars}
iabbrev {'<silent>', "'", "''<left>"..eat_all_chars}

-- these maps will make the abbreviations above work where it normally wouldn't
inoremap('(', '<esc>a(')
inoremap('{', '<esc>a{')
inoremap('[', '<esc>a[')
inoremap('<', '<esc>a<')
inoremap('"', '<esc>a"')
inoremap('\'', '<esc>a\'')

local M = {
    eat_all_chars = eat_all_chars
}
local fn = vim.fn

function M._eatchar(pattern)
    c = fn.getcharstr(0)
    return string.match(c, pattern) and '' or c
end

return M

