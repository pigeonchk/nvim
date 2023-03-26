local autocmd  = vim.api.nvim_create_autocmd

vim.g.author_name = 'Gabriel Manoel'

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

autocmd({'BufNew', 'BufNewFile'}, {
    pattern = '*.c',
    callback = require('license').detect_and_insert_license })

autocmd({'BufNew', 'BufNewFile'}, {
    pattern = '*.h',
    callback = require('license').detect_and_insert_license })

autocmd({'BufNew', 'BufNewFile'}, {
    pattern = '*.h',
    callback = function(tbl)
        if not vim.b.header_guard_inserted then

            local skip = 0
            if vim.b.license_autocmd_has_run then
                skip = vim.api.nvim_buf_line_count(tbl.buf) - 1
            end

            require('ftplugin.header_guard')(tbl.buf, skip)
            vim.b.header_guard_inserted = true
        end
    end})

require('project').setup_if_project()
