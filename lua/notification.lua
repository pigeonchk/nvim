local notify     = require('notify')
local notify_err = require('error')
local uv         = vim.loop
local packer = { }
packer.plugin_utils = require('packer.plugin_utils')

local update_watcher  = { }

update_watcher.is_git_type = function(plugin_path)
    local res = vim.fn.system('git -C '..plugin_path..' status')
    if string.find(res, 'not a git repository') then
        return false
    end
    return true
end

update_watcher.list_installed_git_plugins = function()
    local opt_plugins, start_plugins = packer.plugin_utils.list_installed_plugins()

    local plugins = {}
    function extract_plugin_names(list)
        for k,v in pairs(list) do
            if update_watcher.is_git_type(k) then
                table.insert(plugins, k)
            end
        end
    end

    extract_plugin_names(opt_plugins)
    extract_plugin_names(start_plugins)

    return plugins
end

local PLUGIN_UP_TO_DATE = '#OK#'
local PLUGIN_OUTDATED   = '#OUTDATED#'

update_watcher.thrd_updater_entry = function(plugins_file, tmpfile)

    local plugins = {}
    for line in io.lines(plugins_file) do
        table.insert(plugins, line)
    end

    local system = function(cmd)
        local handle = io.popen(cmd)
        local res = handle:read('a')
        handle:close()
        return res
    end

    local is_branch_up_to_date = function(plugin_path)
        os.execute('git -C '..plugin_path..' remote update')
        local res = system('git -C '..plugin_path..' status -uno')

        if string.find(res, 'Your branch is up to date') then
            return true
        end
        return false
    end

    local plugin_status = {}
    for _, plugin in ipairs(plugins) do
        local status
        local plugin_name = string.match(plugin, '^.*/(.*)$')
        if is_branch_up_to_date(plugin) then
            status = plugin_name..': #OK#\n'
        else
            status = plugin_name..': #OUTDATED#\n'
        end
        table.insert(plugin_status, status)
    end

    local handle = io.open(tmpfile, 'w+')
    handle:write(table.unpack(plugin_status))
    handle:close()
end

update_watcher.start_watcher = function()
    local plugins       = update_watcher.list_installed_git_plugins()
    local plugins_file  = vim.fn.tempname()
    local tmpfile       = vim.fn.tempname()
    vim.fn.writefile(plugins, plugins_file)

    if not uv.new_thread(update_watcher.thrd_updater_entry, plugins_file, tmpfile) then
        notify_err('update watcher', 'failed to create new thread')
        vim.defer_fn(update_watcher.start_watcher, update_watcher.time)
        return
    end

    local WATCH_FILE_EVERY_MS = 5000
    local watch_file = function()
        if #vim.fn.glob(tmpfile) == 0 then
            vim.defer_fn(update_watcher.watch_file, WATCH_FILE_EVERY_MS)
            return
        end

        local to_update = {
            'some plugins are out-of-date:'
        }
        for _, line in ipairs(vim.fn.readfile(tmpfile)) do
            local is_outdated = string.match(line, '#(.*)#') == 'OUTDATED'
            if is_outdated then
                local plugin_name = '    '..string.match(line, '^(.*):')
                table.insert(to_update, plugin_name)
            end
        end

        vim.fn.system('rm '..tmpfile)

        if #to_update > 1 then
            notify(to_update, 'information', {title = 'packer'})
        end
    end
    update_watcher.watch_file = watch_file

    vim.defer_fn(watch_file, WATCH_FILE_EVERY_MS)
    vim.defer_fn(update_watcher.start_watcher, update_watcher.time)
end

local M = {}

function M.setup_watcher(time)
    update_watcher.time = time
    vim.defer_fn(update_watcher.start_watcher, time)
    update_watcher.start_watcher() -- start now
end

return M
