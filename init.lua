local autocmd  = vim.api.nvim_create_autocmd
local augroup  = vim.api.nvim_create_augroup

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
-- ]]

require('plugins') -- first setup the plugins
require('colors').colorscheme('gruvbox',
    { background = 'dark' },
    function()
        local ch_highlight = require('colors').ch_highlight

        ch_highlight('LineNr', {bg = '#303030' })
end)
require('statusline').setup('jellybeans')
require('settings').set_sensible() -- first setup the plugins
require('abbrev')
require('mappings')

require('notification').setup_watcher(60 * 1000)
