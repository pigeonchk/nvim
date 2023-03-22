local upsearch  = require('utils').upsearch

local valid_options = {
    makeprg = { type = 'string' }
}

local M = { }

M.setup_if_project = function()
    local found = upsearch(vim.fn.getcwd(), '.project.json')
    if not found then
        return
    end

    local NOTIFY_TITLE = 'project::setup'
    local NOTIFY_STRING = 'Found \'.project.json\'. Loading project options...'
    vim.notify(NOTIFY_STRING, vim.log.levels.INFO, { title = NOTIFY_TITLE })

    local lines = {}
    for _,line in ipairs(vim.fn.readfile(found)) do
        -- ignore comments
        local str, matches = string.gsub(line, '//.*', '')
        table.insert(lines, str)
    end

    local opts = vim.fn.json_decode(lines)

    for key, val in pairs(opts) do
        if not valid_options[key] then
            if not vim.o[key] then
                vim.notify('unknown option \''..key..'\' found while parsing \'.project.json\'',
                    vim.log.levels.ERROR, {title = NOTIFY_TITLE})
            else
                vim.notify(
                    'option \''..key..'\' not supported found while parsing \'.project.json\'',
                    vim.log.levels.ERROR, {title = NOTIFY_TITLE})
            end
        end

        if type(val) ~= valid_options[key].type then
            vim.notify(
                {'option \''..key..'\' has invalid type in \'.project.json\'.',
                 'expected \''..valid_options[key].type..'\', but got \''..type(val)..'\''},
                vim.log.levels.ERROR, {title = NOTIFY_TITLE})
        else
            vim.go[key] = val
        end
    end
end

return M
