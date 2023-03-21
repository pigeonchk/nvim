local validate      = require('validation').validate
local notify_err    = require('error')
local upsearch      = require('utils').upsearch

local licenses = { }

licenses['MIT'] = [[
MIT License

Copyright (c) %Y Gabriel Manoel

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.]]

local license_names = {
    ['0BSD']                = 'BSD Zero Clause License',
    ['AFL-3.3']             = 'Academic Free License ("AFL") v. 3.0',
    ['AGPL-3.0-or-later']   = 'GNU AFFERO GENERAL PUBLIC LICENSE',
    ['Apache-2.0']          = 'Apache License',
    ['Artistic-2.0']        = 'The Artistic License 2.0',
    ['BSD-2-Clause']        = 'BSD 2-Clause License',
    ['BSD-3-Clause-Clear']  = 'The Clear BSD License',
    ['BSD-3-Clause']        = 'BSD 3-Clause License',
    ['BSD-4-Clause']        = 'BSD 4-Clause License',
    ['BSL-1.0']             = 'Boost Software License - Version 1.0',
    ['CC-BY-4.0']           = 'Attribution 4.0 International',
    ['CC-BY-SA-4.0']        = 'Attribution-ShareAlike 4.0 International',
    -- technically the name of this license is 'Creative Commons Zero v1.0 Universal',
    -- but in the license file the content of the first line is the one below.
    ['CC0-1.0']             = 'Creative Commons Legal Code',
    ['CECILL-2.1']          = 'CONTRAT DE LICENCE DE LOGICIEL LIBRE CeCILL',
    ['CERN-OHL-P-2.0']      = 'CERN Open Hardware Licence Version 2 - Permissive',
    ['CERN-OHL-S-2.0']      = 'CERN Open Hardware Licence Version 2 - Strongly Reciprocal',
    ['CERN-OHL-W-2.0']      = 'CERN Open Hardware Licence Version 2 - Weakly Reciprocal',
    ['ECL-2.0']             = 'Educational Community License',
    ['EPL-1.0']             = 'Eclipse Public License - v 1.0',
    ['EPL-2.0']             = 'Eclipse Public License - v 2.0',
    ['EUPL-1.1']            = 'European Union Public Licence',
    ['EUPL-1.2']            = 'EUROPEAN UNION PUBLIC LICENCE v. 1.2',
    ['GFDL-1.3-or-later']   = 'GNU Free Documentation License',
    ['GPL-2.0-or-later']    = 'GNU GENERAL PUBLIC LICENSE *Version 2',
    ['GPL-3.0-or-later']    = 'GNU GENERAL PUBLIC LICENSE *Version 3',
    ['ISC']                 = 'ISC License',
    ['LGPL-2.1-or-later']   = 'GNU LESSER GENERAL PUBLIC LICENSE *Version 2.1',
    ['LGPL-3.0-or-later']   = 'GNU LESSER GENERAL PUBLIC LICENSE *Version 3',
    ['LPPL-1.3c']           = 'The LaTeX Project Public License',
    ['MIT-0']               = 'MIT No Attribution',
    ['MIT']                 = 'MIT License',
    ['MPL-2.0']             = 'Mozilla Public License Version 2.0',
    ['MS-PL']               = 'Microsoft Public License (Ms-PL)',
    ['MS-RL']               = 'Microsoft Reciprocal License (Ms-RL)',
    ['MulanPSL-2.0']        = '木兰宽松许可证, 第2版',
    ['NCSA']                = 'University of Illinois/NCSA Open Source License',
    ['ODbL-1.0']            = 'ODC Open Database License (ODbL)',
    ['OSL-3.0']             = 'Open Software License ("OSL") v. 3.0',
    ['Unlicense']           = 'This is free and unencumbered software',

}

local M = { }

M.insert_license = function(license_name)
    local SPEC = { license_name = { type = 'string', required = true } }

    if not validate({license_name = license_name}, SPEC) then
        return nil
    end

    if not licenses[license_name] then
        notify_err('license::insert_license',
                   'license "'..license_name..'" does not exist')
        return
    end

    local comment_leader = vim.b.license_comment_leader
    if not comment_leader then
        notify_err('license::insert_license',
                   'b:license_comment_leader not set for '..vim.bo.filetype)
        return
    end

    local buf = vim.api.nvim_get_current_buf()
    local lines = vim.split(licenses[license_name], '\n')

    local commented_lines = vim.tbl_map(function(line)
        if #line == 0 then
            return comment_leader
        end
        -- cannot call vim.fn.strftime on the whole string since the maximum
        -- output is 80 characters, that means the license string will be cut
        -- short. Instead, we need to find the line where the year is located
        -- and call the function on that line.
        if string.find(line, '%Y', 1, true) then
            line = vim.fn.strftime(line)
        end
        return comment_leader .. ' ' .. line
    end, lines)

    table.insert(commented_lines, '')
    vim.api.nvim_buf_set_lines(buf, 0, 0, false, commented_lines)
end

M.detect_and_insert_license = function()
    local filenames = { 'LICENSE', 'LICENSE.txt' }
    local cwd = vim.fn.getcwd()

    local found
    for _,file in ipairs(filenames) do
        found = upsearch(cwd, file)
        if found then
            break
        end
    end

    if not found then
        notify_err('license::detect_and_insert_license',
                  {'LICENSE or LICENSE.txt file was not found during upsearch.',
                   'Cannot automatically insert license to buffer.'})
        return
    end

    -- we assume the name of the license is written in the first line,
    -- or in the case of GNU licenses, the version is in the second line.
    local lines = vim.fn.readfile(found, '', 2)
    local license_name = lines[1]..lines[2]

    local license
    for short_name, long_name in pairs(license_names) do
        if string.find(license_name, long_name) then

            if not licenses[short_name] then
                notify_err('license::detect_and_insert_license',
                           'Found project license "'..short_name..'" but we don\'t have its text.')
                return
            end

            license = short_name
            break
        end
    end

    if license then
        M.insert_license(license)
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
