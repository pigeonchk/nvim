local fn = vim.fn
local iabbrev = require('viml').iabbrev
local inoremap = require('viml').inoremap

local eat_all_chars = '<C-R>=v:lua.require("abbrev")._eatchar(".")<CR>'

local M = {
    eat_all_chars = eat_all_chars
}

function M._eatchar(pattern)
    c = fn.getcharstr(0)
    return string.match(c, pattern) and '' or c
end

return M

