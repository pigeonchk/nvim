local notify_err = require('error')

local M = { }

-- validate that the table is structured according to spec
--
-- the format of spec is:
--
-- spec = {
--     <name> = {
--         type = <type> or {<type1>, <type2>[, ...]},
--         required = true or false,
--         expects = {
--             <value>[, <value>[, ...]] or
--             {<type>, {<values>}},
--             {<type>, {<values>}}[, {<type>, {<values>}}[, ...]]
--         }
--     }
-- }
function M.validate(tbl, spec)
    if not tbl then
        notify_err('validation.validate', "argument 'tbl' is required")
    end

    if type(tbl) ~= 'table' then
        notify_err('validation.validate', "argument 'tbl' is the wrong type: "..
              "received '"..type(tbl).."', expected 'table'")
    end

    if not spec then
        notify_err('validation.validate', "argument 'spec' is required")
    end

    if type(spec) ~= 'table' then
        notify_err('validation.validate', "argument 'spec' is the wrong type: "..
              "received '"..type(spec).."', expected 'table'")
    end

    function tbl_to_str(type_of_val, tbl, _lines)

        local line  = { }

        for _, v in ipairs(tbl) do
            if type(v) == 'string' then
                table.insert(line, v)
            end
        end

        local fullstring
        if not vim.tbl_isempty(line) then
            fullstring = "'"..type_of_val.."': "..table.concat(line, ' or ')
        end

        if not _lines then
            _lines = { }
        end
        for _, v in ipairs(tbl) do
            if type(v) == 'table' then
                table.insert(_lines, tbl_to_str(v[1], v[2], _lines))
            end
        end

        if not vim.tbl_isempty(_lines) then
            local toconcat = fullstring and ', '..fullstring or ''
            return table.concat(_lines, ', ') ..toconcat
        end

        return fullstring
    end

    function check_type(requested, got, key)
        if type(requested) == 'string' then
            if requested ~= got then
                return false
            end
        elseif type(requested) == 'table' then
            for _, tp in ipairs(requested) do
                if check_type(tp, got, key) then
                    return true
                end
            end
        else
            notify_err('validation.validate', {"'spec."..key..".type' is the wrong type: ",
                  "received '"..type(requested).."', expected 'table' or 'string'"})
        end
        return true
    end

    function check_expected(expected, got, key, type_of_val)
        for i, v in ipairs(expected) do
            if type(v) == 'string' then
                if v == got then
                    return true
                end
            elseif type(v) == 'table' then
                local tp_1 = type(v[1])
                local tp_2 = type(v[2])
                if tp_1 ~= 'string' or tp_2 ~= 'table' then
                    notify_err('validation.validate', {"'spec."..key..".expects["..i
                          .."]' is the wrong type: ", "received {'"..tp_1.."', '"
                          ..tp_2.."'}, expected {'string', 'table'}"})
                end

                if v[1] == type_of_val and check_expected(v[2], got, key, type_of_val) then
                    return true
                end
            else
                notify_err('validation.validate', {"'spec."..key..".expects["..i
                      .."]' is the wrong type: ", "received '"
                      ..type(v).."', expected 'table' or 'string'"})
            end
        end

        return false
    end

    local caller = debug.getinfo(2, 'n').name
    for k, v in pairs(spec) do
        if v.required and tbl[k] == nil then
            notify_err(caller, "argument '"..k.."' is required")
        end

        local type_of_val = type(tbl[k])
        if v.type and tbl[k] ~= nil and not check_type(v.type, type_of_val, k) then
            local expected_type
            if type(v.type) == 'table' then
                local l = { }
                for _,tp in ipairs(v.type) do
                    table.insert(l, "'"..tp.."'")
                end
                expected_type = table.concat(l, ' or ')
            else
                expected_type = "'"..v.type.."'"
            end
            notify_err(caller, {"argument '"..k.."' is the wrong type: ",
                  "received '"..type_of_val.."', expected "..expected_type})
        end

        if v.expects and tbl[k] ~= nil then
            if not check_expected(v.expects, tbl[k], k, type_of_val) then
                notify_err(caller, {": argument '"..k.."' has the wrong value: ",
                      "received '"..tbl[k].."', expected "
                      ..tbl_to_str(type_of_val, v.expects)})
            end
        end
    end
end

return M
