local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup

return function(ft, fnref)
    local group_name = 'FTPLUGIN_'..string.upper(ft)
    autocmd('FileType', {
        group = augroup(group_name, {}),
        pattern = ft,
        callback = fnref
    })

    vim.cmd('doautocmd '..group_name..' FileType '..ft)
end
