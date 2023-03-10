local M = { }

function M.setup(name)
    require('lualine').setup {
        options = {
            theme = name,
            -- don't like the triangular separator
            component_separators = '',
            section_separators = ''
        }
    }
end

return M
