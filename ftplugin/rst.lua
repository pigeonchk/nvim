local add_filetype_plugin = require('settings').add_filetype_plugin
add_filetype_plugin('rst', function ()
    require('settings').filetype_setall('rst',
        {
            -- some options to automatically format paragraphs
            formatoptions = 'tnb1',
            textwidth = 79,
            -- rST uses 3 spaces to indent
            shiftwidth = 3,
            tabstop = 3
})
end)
