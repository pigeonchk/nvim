local regex     = vim.regex

return function (module, s)
    local traceback     = debug.traceback('', 2)
    local location      = vim.fn.split(traceback, '\n')[2]
    local match_begin, match_end = regex('^\\s\\+\\(.\\+\\):\\(\\d\\+\\):'):match_str(location)
    local match         = string.sub(location, match_begin+2, match_end)
    local line          = string.match(match, ':%d+:')
    local file          = string.gsub(match, line, '')
    local func          = string.match(location, "'(.*)'") or '<unknown>'
    line = string.gsub(line, ':', '')

    if type(s) == 'string' and string.find(s, '\n') then
        s = vim.fn.split(s, '\n')
    elseif type(s) == 'table' then
        local l = { }
        for _, str in ipairs(s) do
            if string.find(str, '\n') then
                vim.list_extend(l, vim.fn.split(str, '\n'))
            else
                table.insert(l, str)
            end
        end
        s = l
    end

    s = type(s) == 'string' and {s} or s
    vim.list_extend(s, {
        'details:',
        '    file    : '..file,
        '    line    : '..line,
        '    function: '..func,
    })

    vim.notify(s, vim.log.level.ERRORS, { title = module })
end
