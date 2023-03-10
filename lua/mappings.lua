-- vim:foldmethod=marker:foldlevel=0

local noremap = require('viml').noremap
local nnoremap = require('viml').nnoremap
local inoremap = require('viml').inoremap
local vnoremap = require('viml').vnoremap
local tnoremap = require('viml').tnoremap

vim.g.mapleader = ','

-- Moving {{{1

-- using ALT+<key> to change the window
noremap('<A-h>', '<C-w>h')
noremap('<A-l>', '<C-w>l')
noremap('<A-j>', '<C-w>j')
noremap('<A-k>', '<C-w>k')

-- using <Alt+j>+<Alt+k> to exit insert mode
inoremap('<A-j><A-k>', '<esc>')
inoremap('<A-k><A-j>', '<esc>')
inoremap('<A-K><A-J>', '<esc>')
inoremap('<A-J><A-K>', '<esc>')
inoremap('<A-J><A-k>', '<esc>')
inoremap('<A-k><A-J>', '<esc>')
inoremap('<A-j><A-K>', '<esc>')
inoremap('<A-K><A-j>', '<esc>')

-- go to the beginning of the line
nnoremap('H', '0')
-- go to the end of the line
nnoremap('L', '$')

-- exit terminal mode
tnoremap('<esc>', '<C-\\><C-n>')

-- change windows in terminal mode
tnoremap('<A-h>', '<C-\\><C-n><C-w>h')
tnoremap('<A-l>', '<C-\\><C-n><C-w>l')
tnoremap('<A-j>', '<C-\\><C-n><C-w>j')
tnoremap('<A-k>', '<C-\\><C-n><C-w>k')

-- 1}}}

-- Editing {{{1

-- Tab completion {{{2
inoremap('<TAB>', 'v:lua.require("mappings")._tab_completion()', {expr = true, silent = true})
inoremap('<S-TAB>', 'pumvisible() ? "\\<C-P>" : "\\<C-h>"', {expr = true})
inoremap('<C-space>', 'coc#refresh()', {expr = true, silent = true})
inoremap('<cr>',
         'pumvisible() ? coc#_select_confirm() : "\\<C-g>u\\<CR>\\<c-r>=coc#on_enter()\\<CR>"',
         {expr = true, silent = true})

-- 2}}}

-- avoid taking my hand from the home row when wanting to exit insert mode
inoremap('<esc>', '')

-- fast saving
nnoremap('<leader>w', ':w!<CR>', {silent = true})
nnoremap('<leader>sq', ':wq!<CR>', {silent = true})

nnoremap('<leader><space>', ':nohlsearch<CR>', {silent = true})

vnoremap('<tab>', '<esc>')

nnoremap('<leader>ca', '<Plug>(coc-calc-result-append)')
nnoremap('<leader>cr', '<Plug>(coc-calc-result-replace)')

-- 1}}}

nnoremap('<leader>f', ':Files<CR>')

local M = {}

local fn = vim.fn
local api = vim.api

-- [[
--   tab completion for coc.
--
--   It only triggers when there's a non-whitespace character before the cursor.
-- ]]
function M._tab_completion()
    local coc_refresh = fn['coc#refresh']
    local coc_next = fn['coc#pum#next']
    local coc_pumvisible = fn['coc#pum#visible']

    local function is_space_before()
        local current_line = api.nvim_get_current_line()
        local col = fn.col('.') - 1
        return col == 0 or string.find(current_line, '%s', col) == col
    end

    return coc_pumvisible() ~= 0 and coc_next(1) or (is_space_before() and '\t' or coc_refresh())
end

return M
