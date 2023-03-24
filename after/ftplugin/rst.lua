require('ftplugin.create')('rst', function()
    -- some options to automatically format paragraphs
    vim.bo.formatoptions = 'tnb1'
    vim.bo.textwidth = 80
    -- rST uses 3 spaces to indent
    vim.bo.shiftwidth = 3
    vim.bo.softtabstop = 3
end)
