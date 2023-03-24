require('ftplugin.create')('c', function()
    -- indentation
    vim.bo.cindent = true
    -- some options to automatically format comments
    vim.bo.formatoptions = 'croqnb1j'
    -- only for comments, code can still go past it
    vim.bo.textwidth = 79

    vim.b.license_comment_leader = '//'
end)
