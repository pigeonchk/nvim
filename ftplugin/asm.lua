-- vim:foldmethod=marker:foldlevel=0
local add_filetype_plugin = require('settings').add_filetype_plugin

add_filetype_plugin('asm', function ()
    require('settings').filetype_setall('asm',
        {
            -- some options to automatically format comments
            formatoptions = 'croqanb1j',
            -- only for comments, code can still go past it
            textwidth = 79,
            -- set variable tabstops so that the comments always start at line 30
            -- see :h 'vartabstop'
            vartabstop = {4, 30, 4}
})
end)

add_filetype_plugin('asm', function()
    require('settings').filetype_setall('asm',
        {
            -- enable showing <EOL> characters
            list = true,
})
end, true)
