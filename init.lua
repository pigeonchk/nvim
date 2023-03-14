local autocmd  = vim.api.nvim_create_autocmd
local augroup  = vim.api.nvim_create_augroup

vim.g.author_name = 'Gabriel Manoel'

-- [[ layout of folders are as following:
--
--    init.lua -- require() the various lua files
--    lua/
--      |- abbrev.lua       -- all my abbreviations
--      |- align.lua        -- utility functions for text alignment
--      |- colors.lua       -- colorscheme things
--      |- mappings.lua     -- all my mappings
--      |- notice.lua       -- notification API
--      |- plugins.lua      -- initializes then on startup
--      |- re.lua           -- vim regex version of some of lua's string functions
--      |- settings.lua     -- all my vim settings
--      |- statusline.lua   -- configures the statusline
--      |- viml.lua         -- common wrappers around vimscript functions
-- ]]

require('plugins') -- first setup the plugins
require('colors').colorscheme('gruvbox', function()
    vim.o.background = 'dark'
    --
    -- use custom_highlight() here to change any highlighting
    --
end)
require('statusline').setup('jellybeans')
require('settings').set_sensible() -- first setup the plugins
require('abbrev')
require('mappings')

-- this is my custom notification system
require('notice').setup { }

require('notice').notify({'this is a notification', 'a', 'b', 'c'}, {
    module = 'My awesome plugin',
    center_module = true,
    alignment = 'left'
})
require('notice').notify({'this is a notification 2', 'a', 'b', 'c'})
