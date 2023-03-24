require('ftplugin.create')('sh', function()
    -- indentation
    vim.bo.cindent = true
    vim.bo.cinoptions = vim.o.cinoptions .. '#1'
end)
