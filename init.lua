local autocmd  = vim.api.nvim_create_autocmd
local augroup  = vim.api.nvim_create_augroup

vim.g.author_name = 'Gabriel Manoel'
vim.g.author_email = 'gabrielmanoel13@gmail.com'

-- [[ layout of folders are as following:
--
--    init.lua -- require() the various lua files
--    lua/
--      |- abbrev.lua       -- all my abbreviations
--      |- colors.lua       -- colorscheme things
--      |- mappings.lua     -- all my mappings
--      |- plugins.lua      -- initializes then on startup
--      |- re.lua           -- vim regex version of some of lua's string functions
--      |- settings.lua     -- all my vim settings
--      |- statusline.lua   -- configures the statusline
--      |- utils.lua        -- some utility functions that don't belong anywhere else
--      |- validation.lua   -- contains functions to validate options
--      |- viml.lua         -- common wrappers around vimscript functions
--      |- error.lua        -- an error function that shows a notification
-- ]]

require('plugins') -- first setup the plugins
require('colors').colorscheme('gruvbox',
    { background = 'dark' },
    function()
        local ch_highlight = require('colors').ch_highlight

        ch_highlight('LineNr', {bg = '#303030' })
end)
require('statusline').setup('jellybeans')
require('settings').setup() -- first setup the plugins
require('abbrev')
require('mappings')

local buf_get_var = require('viml').buf_get_var
local buf_set_var = require('viml').buf_set_var

local c_fam_augroup = augroup('C_FAMILY_FTPLUGIN', {})

autocmd('BufNewFile', {
    group = c_fam_augroup,
    pattern = '*.c',
    callback = require('license').detect_and_insert_license })

-- do not prefix the header guard with the directory name if
-- the directory is one of these
vim.g.header_guard_prefix_dir_blacklist = { 'src', 'include' }

require('project').setup_if_project()

autocmd('BufNewFile', {
    group = c_fam_augroup,
    pattern = '*.h',
    callback = function(tbl)
        if buf_get_var(tbl.buf, 'header_guard_inserted') then
            return
        end

        local skip = require('license').detect_and_insert_license(tbl)

        require('ftplugin.header_guard')(tbl.buf, skip)
    end})

vim.api.nvim_create_user_command('InsertLicense', function (tbl)
    require('license').insert_license(tbl.args)
end, {force = true, nargs=1})

vim.api.nvim_create_user_command('InsertHeaderGuard', function (tbl)
    local buf = vim.api.nvim_get_current_buf()
    local skip = 0
    local line_count = vim.api.nvim_buf_line_count(buf)

    local found_non_comment = false

    while found_non_comment == false do
        if skip >= line_count then
            skip = line_count
            break
        end

        local lines = vim.api.nvim_buf_get_lines(buf, skip, skip + 5, false)

        for i, line in ipairs(lines) do
            if not string.match(line, '^%s*//') and not string.match(line, '^%s/?%*') then
                found_non_comment = true
                break
            end
            skip = skip + 1
        end

    end

    require('ftplugin.header_guard')(buf, skip)
end, {force = true})

autocmd('BufWinEnter', {
    group = augroup('TXT_WINOPTIONS', {}),
    pattern = '*.txt',
    callback = function(tbl)
        vim.api.nvim_win_set_option(vim.fn.bufwinid(tbl.buf), 'colorcolumn', '80')
    end
})
