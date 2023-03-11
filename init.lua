vim.g.author_name = 'Gabriel Manoel'

-- [[ layout of folders are as following:
--
--    init.lua -- require() the various lua files
--    lua/
--      |- plugins.lua -- initializes then on startup
--
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

require('notice')
