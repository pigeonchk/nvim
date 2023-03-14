local validate = require('validation').validate

local M = { }

M.DEFAULT_BREAKAT         = ' ,.;:=+'
M.DEFAULT_WORDBREAK_CHAR  = '~'

-- get the numbre of spaces needed to center a string of len length
-- in a line of width maxlen.
function M.get_alignment(maxlen, len)
    local rest = maxlen - len
    return rest == 0 and 0 or math.ceil(rest / 2)
end

-- returns a new string centered on a line of fixed width.
function M.centerln(line, width)
    local ARGS_SPEC = {
        line = {
            type = 'string',
            required = true
        },
        width = {
            type = 'number',
            required = true
        }
    }

    validate({line=line, width=width}, ARGS_SPEC)

    local alignment = M.get_alignment(width, #line)
    local spaces = string.rep(' ', alignment)
    return spaces..line
end

-- center a list of strings in lines of fixed width
function M.centerln_l(lines, width)
    local centered_lines = {}
    for _, line in ipairs(lines) do
        table.insert(centered_lines, M.centerln(line, width))
    end

    return centered_lines
end

-- split the line into two or more lines, each at most maxlen of length.
-- it tries to split the line at the nearest space or puctuation, if not
-- able to find any then it uses a wordbreak char as the last character in the line
function M.splitln(what, maxlen, breakat)
    local lines = { }
    local lengths = { }

    local ARGS_SPEC = {
        what    = { type = 'string', required = true },
        maxlen  = { type = 'number', required = true },
        breakat = { type = 'string' }
    }

    validate({what = what, maxlen = maxlen, breakat = breakat}, ARGS_SPEC)

    breakat = breakat or M.DEFAULT_BREAKAT
    -- this removes '-' if the user specifies it with breakat.
    local WORD = string.gsub('[-a-zA-Z0-9_]', breakat, '')
    local PATTERN = '\\('..WORD..'\\+\\|\\s\\+\\|[[:punct:]]\\+\\)'

    -- going into their own function cause of deep nesting issues
    local process_word = function(arg_tbl, word)
        arg_tbl.curr_len = arg_tbl.curr_len + #word

        local breakat_index = string.find(word, '(['..breakat..'])')
        arg_tbl.last_breakat_index = breakat or arg_tbl.last_breakat_index

        table.insert(arg_tbl.line_array, word)

        if breakat_index then
            arg_tbl.last_breakat_word = #arg_tbl.line_array
        end

        local line
        local len
        if arg_tbl.curr_len >= arg_tbl.maxlen then
            if arg_tbl.last_breakat_word then
                -- there is a breakat character in a word we found.
                -- we are going to concatenate the string up until that word.
                -- then calculate the index of the breakat character and take
                -- the substring up until that character.
                breakat_index = arg_tbl.last_breakat_index
                local last_word = arg_tbl.last_breakat_word
                local fullstring = table.concat(arg_tbl.line_array, '', 1, last_word)
                local length_last_word = #arg_tbl.line_array[last_word]
                local loc_from_last = length_last_word - (length_last_word - breakat_index)

                line = string.sub(fullstring, 1, #fullstring - loc_from_last)
            else
                -- there is no breakat character, break the last word in
                -- two parts, the first part has to have maxlen-1 characters
                -- of the original string plus the NOTIFY_DEFAULT_WORDBREAK_CHAR
                -- character.
                local fullstring = table.concat(arg_tbl.line_array)
                line = string.sub(fullstring, 1, arg_tbl.maxlen-1)..M.DEFAULT_WORDBREAK_CHAR
            end
            len = #line
        end

        return { line, len }
    end

    index = 1
    while index < #what do
        local vars = {
            line_array = { },
            curr_len = 0,
            maxlen = maxlen,
            -- last_breakat_word = nil,
            -- last_breakat_index = nil
        }
        local res
        for word in re_gmatch(string.sub(what, index), PATTERN) do
            res = process_word(vars, word)
            if res[1] ~= nil then
                break
            end
        end

        local line, len = table.unpack(res)
        if line == nil then
            -- reached the end of the string and there is some residue
            line = table.concat(vars.line_array)
            len = #line
        end

        table.insert(lines, line)
        table.insert(lengths, len)
        index = index + len
    end

    return { lines, lengths }
end

function M.splitln_l(what, maxlen, breakat)
    local lines = {}
    local lengths = {}

    local ARGS_SPEC = {
        what    = { type = 'table', required = true },
        maxlen  = { type = 'number', required = true },
        breakat = { type = 'string' }
    }

    validate({what = what, maxlen = maxlen, breakat = breakat}, ARGS_SPEC)

    local extend_list = function(lst_output, lst_input)
        for _, val in ipairs(lst_input) do
            table.insert(lst_output, val)
        end
    end

    for _,line in ipairs(what) do
        local len = #line
        if len > maxlen then
            local res = splitln(line, maxlen)
            extend_list(lines, res[1])
            extend_list(lengths, res[2])
        else
            table.insert(lines, line)
            table.insert(lengths, len)
        end
    end

    return { lines, lengths }
end

return M
