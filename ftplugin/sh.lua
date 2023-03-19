-- vim:foldmethod=marker:foldlevel=0

local add_filetype_plugin = require('settings').add_filetype_plugin

add_filetype_plugin('sh', function ()
    require('settings').filetype_setall('sh',
        {
            -- indentation
            cindent = true,
            cinoptions = vim.o.cinoptions .. '#1'
})
end)

add_filetype_plugin('sh', function()
    require('settings').filetype_setall('sh',
        {
            -- enable showing <EOL> characters
            list = true,
})
end, true)
