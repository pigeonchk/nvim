local validate  = require('validation').validate
local expand    = vim.fn.expand

local function insert_guard_at_buf(bufnr, skip)
    skip = skip or 0

    local ext = expand('#'..bufnr..':e')
    local filename = expand('#'..bufnr..':p:t')
    local dir = expand('#'..bufnr..':p:h:t')
    local project = ''

    local fullpath = expand('#'..bufnr..':p')
    project = vim.g.project_name or string.match(fullpath, '/include/(.*)/'..dir)

    if ext ~= 'h' and ext ~= 'hpp' then
        vim.notify({
            'cannot insert header guard at buffer',
            filename..' is not a c/c++ header.'},
            vim.log.levels.ERROR, {title='ftplugin::header_guard'})
    end

    if not vim.g.header_guard_prefix_dir_blacklist or
        not vim.tbl_contains(vim.g.header_guard_prefix_dir_blacklist, dir) then
        filename = dir ..'/'..filename
    end

    if project and string.lower(project) ~= string.lower(dir) then
        if not vim.g.header_guard_prefix_dir_blacklist or
            not vim.tbl_contains(vim.g.header_guard_prefix_dir_blacklist, project) then
            filename = project..'/'..filename
        end
    end

    local macro = string.upper(string.gsub(filename, '[%p%s]', '_'))
    local lines_begin = {
        '#ifndef '..macro,
        '#define '..macro
    }

    local lines_end = {
        '#endif /* '..macro..' */'
    }

    vim.api.nvim_buf_set_lines(bufnr, skip, skip, false, lines_begin)
    vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, lines_end)
end

return function(bufnr, skip)
    local SPEC = {
        bufnr = {type = 'number' }
    }

    if not validate({bufnr = bufnr}, SPEC) then
        return nil
    end

    bufnr = bufnr or vim.api.nvim_get_current_buf()
    insert_guard_at_buf(bufnr, skip)
end
