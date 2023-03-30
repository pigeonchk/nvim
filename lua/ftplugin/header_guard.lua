local validate  = require('validation').validate
local expand    = vim.fn.expand
local buf_get_var = require('viml').buf_get_var
local buf_set_var = require('viml').buf_set_var

local function insert_guard_at_buf(bufnr, skip)
    skip = skip or 0


    local ext = expand('#'..bufnr..':e')
    local filename = expand('#'..bufnr..':p:t')
    local dir = expand('#'..bufnr..':p:h:t')

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
