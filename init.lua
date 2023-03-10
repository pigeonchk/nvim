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
require('settings').set_sensible() -- first setup the plugins
require('abbrev')
require('mappings')

--local au = vim.api.nvim_create_autocmd

--au({'BufNewFile', pattern={'*.c', '*.h'}, callback=require('ftplugin.c').bufnewfile_callback})
