local validate      = require('validation').validate
local notify_err    = require('error')
local upsearch      = require('utils').upsearch
local trim          = require('utils').trim

-- a good place to get these headers are https://spdx.org/licenses/
local license_headers = {
    ['GPL-3.0-or-later'] = {
        'Copyright (C) %Y <author> (<author_email>)',
        '',
        'This program is free software: you can redistribute it and/or modify it under',
        'the terms of the GNU General Public License as published by the Free Software',
        'Foundation, either version 3 of the License, or (at your option) any later',
        'version.',
        '',
        'This program is distributed in the hope that it will be useful, but WITHOUT ANY',
        'WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A',
        'PARTICULAR PURPOSE. See the GNU General Public License for more details.',
        '',
        'You should have received a copy of the GNU General Public License along with',
        'this program. If not, see <https://www.gnu.org/licenses/>.'
    }
}

local license_names = {
    ['GPL-2.0-or-later']    = 'GNU GENERAL PUBLIC LICENSE Version 2',
    ['GPL-3.0-or-later']    = 'GNU GENERAL PUBLIC LICENSE Version 3',
    ['LGPL-2.1-or-later']   = 'GNU LESSER GENERAL PUBLIC LICENSE Version 2.1',
    ['LGPL-3.0-or-later']   = 'GNU LESSER GENERAL PUBLIC LICENSE Version 3',
    ['MIT']                 = 'MIT License',
    ['Unlicense']           = 'This is free and unencumbered software',

}

local M = { }

M.insert_license = function(license_spdx)
    local SPEC = { license_spdx = { type = 'string', required = true } }

    if not validate({license_spdx = license_spdx}, SPEC) then
        return nil
    end

    if not license_names[license_spdx] then
        notify_err('license::insert_license',
                   'license "'..license_spdx..'" does not exist')
        return
    end

    header = license_headers[license_spdx]
    if not header then
        notify_err('license::insert_license',
                   'license "'..license_spdx..'" is missing a standard header')
        return
    end

    local comment_leader = vim.b.license_comment_leader
    if not comment_leader then
        notify_err('license::insert_license',
                   'b:license_comment_leader not set for '..vim.bo.filetype)
        return
    end

    local buf = vim.api.nvim_get_current_buf()

    local commented_lines = {
        comment_leader..' SPDX-License-Identifier: '..license_spdx,
        comment_leader
    }

    for _, line in ipairs(header) do
        if line:find('%%Y') then
            line = vim.fn.strftime(line)
        end
        if line:find('<author>') then
            line = string.gsub(line, '<author>', vim.g.author_name)
        end
        if line:find('<author_email>') then
            line = string.gsub(line, '<author_email>', vim.g.author_email)
        end

        if line ~= '' then
            line = ' '..line
        end

        table.insert(commented_lines, comment_leader..line)
    end

    table.insert(commented_lines, '')

    vim.api.nvim_buf_set_lines(buf, 0, 0, false, commented_lines)

    return #commented_lines
end

M.detect_and_insert_license = function(tbl)
    local filenames = { 'LICENSE', 'LICENSE.txt', 'COPYING' }
    local cwd = vim.fn.getcwd()

    if tbl and tbl.event == 'BufNew' and vim.fn.glob(tbl.file) then
        return
    end

    local found
    for _,file in ipairs(filenames) do
        found = upsearch(cwd, file)
        if found then
            break
        end
    end

    if not found then
        notify_err('license::detect_and_insert_license',
                  {'LICENSE, LICENSE.txt, or COPYING file was not found during upsearch.',
                   'Cannot automatically insert license to buffer.'})
        return
    end

    -- we assume the name of the license is written in the first two lines
    local lines = vim.fn.readfile(found, '', 2)
    local license_name = trim(lines[1])..' '..trim(lines[2])

    local license
    for spdx, name in pairs(license_names) do
        if string.find(license_name, name) then
            license = spdx
            break
        end
    end

    if license then
        return M.insert_license(license)
    else
        local fields = vim.split(found, '/')
        local filename = fields[#fields]
        notify_err('license::detect_and_insert_license',
                  {'Didn\'t find a license in '..filename..' that we know about.',
                   'Add it to lua/licenses.lua to be able to automatically insert this license.'})
        return
    end
end

return M
