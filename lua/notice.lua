-- pop.create(what, vim_options)
--
-- returns: { win_id, { border } }
--
-- vim_options are:
--
-- minwidth         - minimum width
-- maxwidth         - maximum width
-- minheight        - minimum width
-- maxheight        - maximum width
-- width            - the requested width (default to 1). If no width is supplied
--                    then it uses the the length of the longest line. unfortunately,
--                    it doesn't take the length of the title into account so it will
--                    not show the full title of the content is less.
-- height           - NOT IMPLEMENTED?? currently it sets to the amount of lines in
--                    the passed argument what.
-- pos              - set from where the popup will be anchored.
--                    values are: 'topleft', 'topright', 'botleft', 'botright'
--                    (default: topleft)
-- col              - the column where the popup will be positioned.
--                    Can be a number for absolute positioning or a string for
--                    cursor relative positioning. The format of the string is:
--                    'cursor+[0-9]+'.
-- line             - same as col but for the row in which the popup will be
--                    positioned.
-- posinvert        - When FALSE the value of "pos" is always used.  When TRUE,
--                    the popup is adjusted vertically when it does not fit in
--                    the screen.
-- title            - title of the window
-- border           - can be a boolean or a table. If its a boolean of a empty
--                    table then the default thickness of the border will be
--                    used. (default: 1)
-- borderchars      - the characters used as borders, must be a table of 8 character
--                    (default: "╔", "╗", "═", "║", "║", "╚", "╝", "═")
-- cursorline       - show the cursor line or not (default: false)
-- wrap             - should long text wrap or not (default: false)
-- time             - close the window on a timer. In milliseconds.
-- highlight        - set the highlight group name for the Normal highlight group
--                    for text.
-- borderhighlight  - set the highlight group name for the Normal highlight group
--                    for the border.
-- padding          - List with numbers, defining the padding above/right/below/left
--                    of the popup (similar to CSS). An empty list uses a padding of
--                    1 all around.  The padding goes around the text, inside any
--                    border. Padding uses the 'wincolor' highlight.
-- callback         - a callback that will be called on <CR> pressed. The window will
--                    close after the callback is called. The signature of the callback
--                    is callback(win_id, first_line).
-- enter            - set the focus to the popup
-- moved            - NOT FULLY IMPLEMENTED YET
-- hidden           - NOT FULLY IMPLEMENTED YET
local popup         = require('plenary.popup')
local re_gmatch     = require('re').re_gmatch
local centerln      = require('align').centerln
local centerln_l    = require('align').centerln_l
local get_alignment = require('align').get_alignment
local splitln       = require('align').splitln
local splitln_l     = require('align').splitln_l
local validate      = require('validation').validate

local TEXT_HIGHLIGHT_GROUP_NAME   = "HI_GRP_POPUP_NOTICE_TEXT"
local BORDER_HIGHLIGHT_GROUP_NAME = "HI_GRP_POPUP_NOTICE_BORDER"
local POPUP_BORDER_COLOR          = '#595959'
local BORDER_DEFAULT_CHARACTERS   = {'─', '│', '─', '│', '╭', '╮', '╯', '╰'}

local NOTIFY_DEFAULT_PADDING         = { 0, 0, 0, 0 }
local NOTIFY_DEFAULT_TIME            = 5000 -- 5 seconds
local NOTIFY_DEFAULT_TITLE           = ''
local NOTIFY_DEFAULT_RIGHT_MARGIN    = 1
local NOTIFY_DEFAULT_TOP_MARGIN      = 1
local NOTIFY_DEFAULT_WIDTH           = 35
local NOTIFY_DEFAULT_ALIGNMENT       = 'center'
local NOTIFY_DEFAULT_ICONS           = {'', '', '', ''} -- info, success, failure, warning
local NOTIFY_DEFAULT_BORDER_COLORS   = {
    '#6ea2dd', -- info
    '#8ec07c', -- success
    '#fb4934', -- failure
    '#fabd2f'  -- warning
}
local NOTIFY_HIGHLIGHT_GROUPS = {
    'HI_GRP_NOTIFY_BORDER_INFO',
    'HI_GRP_NOTIFY_BORDER_SUCCESS',
    'HI_GRP_NOTIFY_BORDER_FAILURE',
    'HI_GRP_NOTIFY_BORDER_WARNING',
}


local INFO      = 1
local SUCCESS   = 2
local FAILURE   = 3
local WARNING   = 4

local CONFIG = {
    -- notify_popup_title = NOTIFY_DEFAULT_TITLE,
    -- notify_right_margin = NOTIFY_DEFAULT_RIGHT_MARGIN,
    -- notify_top_margin = NOTIFY_DEFAULT_TOP_MARGIN,
    -- notify_icons = NOTIFY_DEFAULT_ICONS,
    -- notify_text_aligment = NOTIFY_DEFAULT_ALIGNMENT,
}

local M = { }

-- these are the options:
--
-- border_color         - the border color of popups created with popup_create().
--                        defaults to POPUP_BORDER_COLOR. (a string required)
-- notify_border_colors - the border color of the notification created with
--                        notify(). defaults to NOTIFY_DEFAULT_BORDER_COLORS.
--                        (a table is required)
-- notify_popup_title   - title of the notification popup window itself. defaults
--                        to NOTIFY_DEFAULT_TITLE. expects a string.
-- notify_top_margin    - top margin of the popup window. default to
--                        NOTIFY_DEFAULT_TOP_MARGIN. expects a number.
-- notify_right_margin  - right margin of the popup window. default to
--                        NOTIFY_DEFAULT_RIGHT_MARGIN. expects a number.
-- notify_icons         - the icons used when a module/plugin name is passed
--                        to the notify() function. Must be a list of four
--                        strings, in the format: {info, success, error, warn}
-- notify_text_aligment - notification text alignment. expects one of: 'center' or 'left'.
function M.setup(options)
    if options and type(options) ~= 'table' then
        error('notice.setup: \'options\' is the wrong type: received \''
              ..type(options)..'\', required: \'table\'')
    end

    local shallow_copy = function(tbl)
        local tbl = {}
        for k,v in pairs(tbl) do
            tbl[k] = v
        end
        return tbl
    end

    -- use the same background as the main window
    local normal_hl = vim.api.nvim_get_hl_by_name('Normal', true)
    vim.api.nvim_set_hl(0, TEXT_HIGHLIGHT_GROUP_NAME, normal_hl)

    local border_hl = shallow_copy(normal_hl)
    border_hl.fg = options.border_color or POPUP_BORDER_COLOR
    vim.api.nvim_set_hl(0, BORDER_HIGHLIGHT_GROUP_NAME, border_hl)

    local notify_border_hl = shallow_copy(normal_hl)
    local colors = options.notify_border_color or NOTIFY_DEFAULT_BORDER_COLORS

    notify_border_hl.fg = colors[INFO]
    vim.api.nvim_set_hl(0, NOTIFY_HIGHLIGHT_GROUPS[INFO], notify_border_hl)
    notify_border_hl.fg = colors[SUCCESS]
    vim.api.nvim_set_hl(0, NOTIFY_HIGHLIGHT_GROUPS[SUCCESS], notify_border_hl)
    notify_border_hl.fg = colors[FAILURE]
    vim.api.nvim_set_hl(0, NOTIFY_HIGHLIGHT_GROUPS[FAILURE], notify_border_hl)
    notify_border_hl.fg = colors[WARNING]
    vim.api.nvim_set_hl(0, NOTIFY_HIGHLIGHT_GROUPS[WARNING], notify_border_hl)

    CONFIG.notify_popup_title   = options.notify_popup_title or NOTIFY_DEFAULT_TITLE
    CONFIG.notify_right_margin  = options.notify_right_margin or NOTIFY_DEFAULT_RIGHT_MARGIN
    CONFIG.notify_top_margin    = options.notify_top_margin or NOTIFY_DEFAULT_TOP_MARGIN
    CONFIG.notify_icons         = options.notify_icons or NOTIFY_DEFAULT_ICONS
    CONFIG.notify_text_aligment = options.notify_text_aligment or NOTIFY_DEFAULT_ALIGNMENT
end

-- this function wraps around the popup.create() function to
-- add new functionality.
--
-- Additions:
--
-- * If border was not included, then a border will be given.
--
-- * If borderchars was not included, then it will be set to
--   BORDER_DEFAULT_CHARACTERS.
--
-- * If title is included in vim_options, and the minwidth is
--   not specified or is less than the length of title, then
--   minwidth will be set to the length of the title.
--
-- * If highlight and/or borderhighlight is not given in
--   vim_options, then it will be set to TEXT_HIGHLIGHT_GROUP_NAME
--   and BORDER_HIGHLIGHT_GROUP_NAME, respectively.
function M.popup_create(what, _vim_options)
    local vim_options = {}

    if not _vim_options then
        error("notice.popup_create: argument required: 'vim_options' (a table)")
    end

    for k,v in pairs(_vim_options) do
        vim_options[k] = v
    end

    if vim_options.border == nil then
        vim_options.border = true
    end

    if vim_options.borderchars == nil then
        vim_options.borderchars = BORDER_DEFAULT_CHARACTERS
    end

    if vim_options.title then
        local title_len = string.len(vim_options.title)
        local minwidth = vim_options.minwidth or title_len

        if minwidth < title_len then
            minwidth = title_len
        end
        vim_options.minwidth = minwidth
    end

    if not vim_options.highlight then
        vim_options.highlight = TEXT_HIGHLIGHT_GROUP_NAME
    end

    if not vim_options.borderhighlight then
        vim_options.borderhighlight = BORDER_HIGHLIGHT_GROUP_NAME
    end

    return popup.create(what, vim_options)
end

-- options:
--
-- time             - time the notification will stay up
-- module           - module/plugin name
-- center_module    - center the module name
-- type             - the type of the notification. can be either:
--                  - 'information', 'success', 'failure', 'warning'.
--                    defaults to 'information'.
-- alignment        - alignment of the text. can be either 'center' or 'left'.
--                    defaults NOTIFY_DEFAULT_ALIGNMENT.
function M.notify(what, options)
    options = options or { }

    local ARGS_SPEC = {
        what = {
            type = {'string', 'table'},
            required = true
        },
        options = {
            type = 'table',
        }
    }

    validate({what = what, options=options}, ARGS_SPEC)

    local OPTIONS_SPEC = {
        time            = { type = 'number' },
        module          = { type = 'string' },
        center_module   = { type = 'boolean' },
        alignment       = { type = 'string', expects = {'center', 'left'} },
        type            = {
            type = 'string',
            expects = {'information', 'success', 'failure', 'warning'}
        }

    }

    validate(options, OPTIONS_SPEC)

    local notify_type = options.type or 'information'
    local TYPE_MAP = {
        information = INFO,
        success = SUCCESS,
        failure = FAILURE,
        warning = WARNING,
    }
    local HIGROUP_MAP = {
        information = NOTIFY_HIGHLIGHT_GROUPS[INFO],
        success = NOTIFY_HIGHLIGHT_GROUPS[SUCCESS],
        failure = NOTIFY_HIGHLIGHT_GROUPS[FAILURE],
        warning = NOTIFY_HIGHLIGHT_GROUPS[WARNING],
    }

    local width = NOTIFY_DEFAULT_WIDTH
    local alignment = options.alignment or CONFIG.notify_text_aligment

    -- the algorithm to center the lines is really simple:
    --
    -- - first split any line greater than maxlen into two or more lines.
    -- - calculate the alignment such that the left side has at most 1 character
    --   less than the right side.
    -- - fill up the lines after skipping the alignment characters.
    local align_lines = function(what, maxlen)
        local lines = {}
        local lengths = {}
        if type(what) == 'string' then
            if #what > maxlen then
                lines, lengths = table.unpack(splitln(what, maxlen))
            else
                lines = {what}
                lengths = {#what}
            end
        elseif type(what) == 'table' then
            lines, lengths = table.unpack(splitln_l(what, maxlen))
        end

        if alignment == 'center' then
            return centerln_l(lines, maxlen)
        end
        return lines
    end

    local lines = align_lines(what, width)

    local module_name = options.module
    if module_name then
        -- also optionally center the module name
        -- subtract two to account for the starting space and icon
        local spaces = ' '
        if options.center_module then
            spaces = string.rep(' ', get_alignment(width, #module_name) - 2)
        end

        local icon = CONFIG.notify_icons[TYPE_MAP[notify_type]]
        module_name = ' '..icon..spaces..module_name
        table.insert(lines, 1, string.rep('─', width))
        table.insert(lines, 1, module_name)
    end

    local height = #lines
    -- the anchor is in the north-west, so we need to calculate:
    --
    -- for column:
    --      col = max_column - RIGHT_MARGIN - width - border_thickness.right
    --
    -- for row:
    --     check if height + border_thickness.top + TOP_MARGIN <= max_row
    --     if true:
    --         row = border_thickness.top + TOP_MARGIN + 1
    local calculate_position = function(width, height)
        local RIGHT_MARGIN = CONFIG.notify_right_margin
        local TOP_MARGIN = CONFIG.notify_top_margin
        local border_thickness = require('plenary.window.border')._default_thickness
        local max_column = vim.go.columns

        local total_width = RIGHT_MARGIN + width + border_thickness.right
        if max_column < total_width then
            error('notice.notify: could not create notification: window width too small')
        end
        local col = max_column - total_width

        local max_row = vim.o.lines
        local total_height = TOP_MARGIN + border_thickness.top + height
        if max_row < total_height then
            error('notice.notify: could not create notification: window height too small')
        end

        -- the windows is positioned such that the first line of the windows that is not
        -- a border will be the the row you specified. So in addition to the TOP_MARGIN
        -- and border_thickness.top, we need to add one to skip that line. That way, we
        -- get TOP_MARGIN of space.
        local row = TOP_MARGIN + border_thickness.top + 1
        vim.b.position = {col, row, max_column, total_width, max_row, total_height}
        return {col, row}
    end

    local col, row = unpack(calculate_position(width, height))

    local vim_options = {
        width = width,
        maxwidth = width,
        col = col,
        line = row,
        title = CONFIG.notify_popup_title,
        wrap = true,
        padding = NOTIFY_DEFAULT_PADDING,
        --time = options.time or NOTIFY_DEFAULT_TIME,
        border = true,
        borderhighlight = HIGROUP_MAP[notify_type],
        borderchars = BORDER_DEFAULT_CHARACTERS,
        highlight = TEXT_HIGHLIGHT_GROUP_NAME
    }

    -- create a non-listed scratch buffer
    local bufnr = vim.api.nvim_create_buf(false, true)
    if bufnr == 0 then
        error('notice.notify: failed to create new scratch buffer')
    end

    vim.api.nvim_buf_set_lines(bufnr, 0, 1, true, lines)

    if module_name then
        vim.api.nvim_buf_add_highlight(bufnr, 0, HIGROUP_MAP[notify_type], 0, 0, -1)
        vim.api.nvim_buf_add_highlight(bufnr, 0, HIGROUP_MAP[notify_type], 1, 0, -1)
    end

    return popup.create(bufnr, vim_options)
end

return M
