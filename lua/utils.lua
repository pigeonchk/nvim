local validate = require('validation').validate

local M = { }

function M.tbl_shallowcopy(tbl)

    validate({tbl = tbl}, {tbl={type='table', required=true}})

    local new_tbl = { }
    for k, v in pairs(tbl) do
        new_tbl[k] = v
    end

    return new_tbl
end

return M
