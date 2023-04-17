local validate  = require('validation').validate
local re_gmatch = require('re').re_gmatch

local M = { }

function M.tbl_shallowcopy(tbl)
    if not validate({tbl = tbl}, {tbl={type='table', required=true}}) then
        return nil
    end

    local new_tbl = { }
    for k, v in pairs(tbl) do
        new_tbl[k] = v
    end

    return new_tbl
end

-- taken from: https://stackoverflow.com/a/41943392/18443177
function M.tbl_toprint(tbl, indent)

    local SPEC = {
        tbl = {type = 'table', required = true},
        indent = { type = 'number' }
    }

    if not validate({tbl=tbl, indent=indent}, SPEC) then
        return nil
    end

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

function M.upsearch(path, filename)
    local SPEC = {
        path = { type = 'string' },
        filename = { type = 'string' },
    }

    if not validate({path = path, filename = filename}, SPEC) then
        return nil
    end

    local splitted = vim.split(path, '/')
    local dirs = { }
    local current_dir = ''
    for _,dir in ipairs(splitted) do
        if dir ~= '' then
            current_dir = current_dir..'/'..dir
            table.insert(dirs, current_dir)
        end
    end

    for _ = 1, #dirs do
        local file_to_test = table.remove(dirs, #dirs)..'/'..filename
        if vim.fn.glob(file_to_test) ~= '' then
            return file_to_test
        end
    end

    return nil
end

function M.trim(s)
    local SPEC = {
        s = { type = 'string' },
    }

    if not validate({s = s}, SPEC) then
        return nil
    end

    return string.gsub(string.gsub(s, '^%s+', ''), '%s+$', '')
end

return M
