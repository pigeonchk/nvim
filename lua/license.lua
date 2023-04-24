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
    },
    ['MPL-2.0'] = {
        'Copyright (C) %Y <author> (<author_email>)',
        '',
        'This Source Code Form is subject to the terms of the Mozilla Public',
        'License, v. 2.0. If a copy of the MPL was not distributed with this',
        'file, You can obtain one at https://mozilla.org/MPL/2.0/.'
    }
}

local function get_score_from_pattern(s, pattern)
    local score = 0

    local pattern_components = vim.fn.split(pattern, '/')
    local s_components = vim.fn.split(s, '/')

    for i, c in ipairs(pattern_components) do
        if c ~= '*' and c ~= s_components[i] then
            break;
        end
        score = score + 1
    end

    return score
end

local NOTIFY_TITLE = 'license'

local M = { }

M.insert_license = function(license_spdx)
    local SPEC = { license_spdx = {
        type     = 'string',
        required = true,
        expects  = vim.tbl_keys(license_headers)
    }}

    if string.lower(license_spdx) == 'unlicensed' then
        return
    end

    if not validate({license_spdx = license_spdx}, SPEC) then
        return nil
    end

    local header = license_headers[license_spdx]

    local comment_leader = vim.b.license_comment_leader
    if not comment_leader then
        notify_err(NOTIFY_TITLE, 'b:license_comment_leader not set for '..vim.bo.filetype)
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
    if tbl and tbl.event == 'BufNew' and vim.fn.glob(tbl.file) then
        return
    end

    if not vim.g.project_root then
        notify_err(NOTIFY_TITLE,
            "cannot auto-insert license header: no '.project.json' found.")
        return
    end

    if not vim.g.project_licenses then
        notify_err(NOTIFY_TITLE,
            "'licenses' not defined in '.project.json'.")
        return
    end

    local file = tbl and tbl.file or vim.fn.expand('%:p')

    local patterns = vim.tbl_keys(vim.g.project_licenses)

    local max_score = 0
    local current_pattern
    for _, pattern in ipairs(patterns) do
        local score = get_score_from_pattern(file, pattern)
        if score > max_score then
            max_score = score
            current_pattern = pattern
        end
    end

    local license_spdx = vim.g.project_licenses[current_pattern]
    return M.insert_license(license_spdx)

end

return M
