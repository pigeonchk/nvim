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
-- height           - NOT IMPLEMENTED?? currently it sets to the amount of
--                    lines in the passed argument what.
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
local popup = require('plenary.popup')

local TEXT_HIGHLIGHT_GROUP_NAME = "HI_GRP_POPUP_NOTICE_TEXT"
local BORDER_HIGHLIGHT_GROUP_NAME = "HI_GRP_POPUP_NOTICE_BORDER"
local BORDER_COLOR = '#595959'
local BORDER_DEFAULT_CHARACTERS = {'─', '│', '─', '│', '╭', '╮', '╯', '╰'}

local NOTIFY_DEFAULT_PADDING = { 1, 1, 1, 1 }
local NOTIFY_DEFAULT_TIME = 5000 -- 5 seconds
local NOTIFY_DEFAULT_TITLE = 'notification'
local NOTIFY_DEFAULT_RIGHT_MARGIN = 2
local NOTIFY_DEFAULT_TOP_MARGIN = 3
local NOTIFY_DEFAULT_WIDTH = 35

-- use the same background as the main window
local normal_hl = vim.api.nvim_get_hl_by_name('Normal', true)
local border_hl = {}

for k,v in pairs(normal_hl) do
    border_hl[k] = v
end

border_hl.fg = BORDER_COLOR

vim.api.nvim_set_hl(0, TEXT_HIGHLIGHT_GROUP_NAME, normal_hl)
vim.api.nvim_set_hl(0, BORDER_HIGHLIGHT_GROUP_NAME, border_hl)

local M = { }

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

function M.notify(what, title, time)

    if not what then
        error("notice.notify: argument required: 'what' (a string or a list of strings)")
    end

    local width = NOTIFY_DEFAULT_WIDTH
    local height = #what

    -- the anchor is in the north-west, so we need to calculate:
    --
    -- for column:
    --      col = max_column - NOTIFY_DEFAULT_RIGHT_MARGIN - width - border_thickness.right
    --
    -- for row:
    --     check if height + border_thickness.top + NOTIFY_DEFAULT_TOP_MARGIN > max_row
    --     if true:
    --         row = NOTIFY_DEFAULT_TOP_MARGIN + border_thickness.top
    local calculate_position = function(width, height)
        local border_thickness = require('plenary.window.border')._default_thickness
        local max_column = vim.go.columns

        local total_width = NOTIFY_DEFAULT_RIGHT_MARGIN + width + border_thickness.right
        if max_column < total_width then
            error('notice.notify: could not create notification: window width too small')
        end
        local col = max_column - total_width

        local max_row = vim.o.lines
        local total_height = NOTIFY_DEFAULT_TOP_MARGIN + border_thickness.top + height
        if max_row < total_height then
            error('notice.notify: could not create notification: window height too small')
        end

        local row = NOTIFY_DEFAULT_RIGHT_MARGIN + border_thickness.top

        vim.b.position = {col, row, max_column, total_width, max_row, total_height}
        return {col, row}
    end

    local col, row = unpack(calculate_position(width, height))

    local vim_options = {
        width = width,
        col = col,
        line = row,
        title = title or NOTIFY_DEFAULT_TITLE,
        wrap = true,
        padding = NOTIFY_DEFAULT_PADDING,
        time = time or NOTIFY_DEFAULT_TIME
    }

    return M.popup_create(what, vim_options)
end

--M.popup_create({'this is a long line', 'short', 'long long'}, {})
M.notify({'this is a long line', 'short', 'long long'})


return M
