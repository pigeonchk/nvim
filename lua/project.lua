local upsearch  = require('utils').upsearch
local sformat   = require('utils').sformat

local valid_options = {
    makeprg     = { type = 'string' },
}

local valid_variables = {
    -- the directory to find the executable
    builddir        = { type = 'string' },
    -- the name of the executable to run with :Run
    target          = { type = 'string' },
    -- name of the project
    project         = { type = 'string', alt="name" },
    -- list of licenses used by the project
    licenses        = { type = 'table' }
}

local NOTIFY_TITLE = 'project::setup'

local INVALID_OPTION = {
    "option '$vim_option' has invalid type in '.project.json'.",
    "expectd '$valid_type', but got '$invalid_type'."
}

local function set_option(opt, val)
    if type(val) ~= valid_options[opt].type then
        local params  = {
            vim_option   = opt,
            valid_type   = valid_options[opt].type,
            invalid_type = type(opt)
        }
        vim.notify(sformat(INVALID_OPTION, params),
            vim.log.levels.ERROR, {title = NOTIFY_TITLE})
    else
        vim.go[val] = val
    end
end

local function set_var(var, val)
    local varname = valid_variables[var].alt or var
    vim.g['project_'..varname] = val
end

local function create_run_command()
    if vim.g.project_target and vim.g.project_builddir then
        local builddir
        if vim.g.project_builddir[1] == '/' then
            builddir = vim.g.project_builddir
        else
            builddir = vim.fn.getcwd() ..'/'..vim.g.project_builddir
        end

        local cmd = builddir .. '/'.. vim.g.project_target
        vim.api.nvim_create_user_command('Run', function(tbl)
            vim.cmd('!'..cmd..' '..tbl.args)
        end, {force = true, nargs='*'})
    end
end

local M = { }

M.setup_if_project = function()
    local found = upsearch(vim.fn.getcwd(), '.project.json')
    if not found then
        return
    end

    local NOTIFY_STRING = "Found '.project.json'. Loading project options..."
    vim.notify(NOTIFY_STRING, vim.log.levels.INFO, { title = NOTIFY_TITLE })

    local lines = {}
    for _,line in ipairs(vim.fn.readfile(found)) do
        -- ignore comments
        local str, matches = string.gsub(line, '//.*', '')
        table.insert(lines, str)
    end

    local opts = vim.fn.json_decode(lines)

    for key, val in pairs(opts) do
        if valid_options[key] then
            set_option(key, val)
        elseif valid_variables[key] then
            set_var(key, val)
        elseif not vim.tbl_get(vim.go, key) then
                vim.notify("unknown option '"..key.."' found while parsing '.project.json'",
                    vim.log.levels.ERROR, {title = NOTIFY_TITLE})
        else
            vim.notify("option '"..key.."' not supported found while parsing '.project.json'",
                vim.log.levels.ERROR, {title = NOTIFY_TITLE})
        end
    end

    create_run_command()
end

return M
