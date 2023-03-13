local regex_compile = vim.regex

local M = { }

-- Returns an iterator that each time it is called it returns a new match.
-- Similar to lua's string.gmatch, but using vim regex.
function M.re_gmatch(str, re)
    local re = regex_compile(re)
    return function ()
        local match_begin, match_end = re:match_str(str)

        -- basically sets the next re:match_str to always returns nil
        if match_begin == nil then
            position = #str + 1
            return
        end

        -- regex:match_str() returns the byte offset, but lua indexes start at 1 :\
        local match = string.sub(str, match_begin+1, match_begin + match_end)
        str = string.sub(str, match_begin + match_end + 1)

        return match
    end
end

return M
