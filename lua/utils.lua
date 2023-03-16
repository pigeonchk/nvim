local validate  = require('validation').validate
local re_gmatch = require('re').re_gmatch
local notify    = require('notify')

local M = { }

function M.tbl_shallowcopy(tbl)

    validate({tbl = tbl}, {tbl={type='table', required=true}})

    local new_tbl = { }
    for k, v in pairs(tbl) do
        new_tbl[k] = v
    end

    return new_tbl
end

-- taken from: https://stackoverflow.com/a/41943392/18443177
function M.tbl_toprint(tbl, indent)
    if not indent then indent = 0 end
    local toprint = string.rep(" ", indent) .. "{\n"
    indent = indent + 2
    for k, v in pairs(tbl) do
        toprint = toprint .. string.rep(" ", indent)
        if (type(k) == "number") then
            toprint = toprint .. "[" .. k .. "] = "
        elseif (type(k) == "string") then
            toprint = toprint  .. k ..  " = "
        end

        if (type(v) == "number") then
            toprint = toprint .. v .. ",\n"
        elseif (type(v) == "string") then
            toprint = toprint .. "\"" .. v .. "\",\n"
        elseif (type(v) == "table") then
            toprint = toprint .. M.tbl_toprint(v, nil, indent + 2) .. ",\n"
        else
            toprint = toprint .. "\"" .. tostring(v) .. "\",\n"
        end
    end
    toprint = toprint .. string.rep(" ", indent-2) .. "}"
    return toprint
end


return M
