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
local popup = require('plenary.popup')
local re_gmatch = require('re').re_gmatch

local TEXT_HIGHLIGHT_GROUP_NAME = "HI_GRP_POPUP_NOTICE_TEXT"
local BORDER_HIGHLIGHT_GROUP_NAME = "HI_GRP_POPUP_NOTICE_BORDER"
local POPUP_BORDER_COLOR = '#595959'
local BORDER_DEFAULT_CHARACTERS = {'─', '│', '─', '│', '╭', '╮', '╯', '╰'}

local NOTIFY_DEFAULT_PADDING = { 0, 0, 0, 0 }
local NOTIFY_DEFAULT_TIME = 5000 -- 5 seconds
local NOTIFY_DEFAULT_TITLE = ''
local NOTIFY_DEFAULT_RIGHT_MARGIN = 1
local NOTIFY_DEFAULT_TOP_MARGIN = 1
local NOTIFY_DEFAULT_WIDTH = 35
local NOTIFY_DEFAULT_BORDERHIGHLIGHT = 'HI_GRP_NOTIFY_BORDER'
local NOTIFY_DEFAULT_BORDER_COLOR = '#6ea2dd'
local NOTIFY_DEFAULT_LINE_BREAKAT = ' ,.;:=+'
local NOTIFY_DEFAULT_WORDBREAK_CHAR = '~'

local CONFIG = {
    -- notify_line_breakat = NOTIFY_DEFAULT_LINE_BREAKAT,
    -- notify_popup_title = NOTIFY_DEFAULT_TITLE,
    -- notify_right_margin = NOTIFY_DEFAULT_RIGHT_MARGIN,
    -- notify_top_margin = NOTIFY_DEFAULT_TOP_MARGIN,
}

local M = { }

-- these are the options:
--
-- border_color         - the border color of popups created with popup_create().
--                        defaults to POPUP_BORDER_COLOR. (a string required)
-- notify_border_color  - the border color of the notification created with
--                        notify(). defaults to NOTIFY_DEFAULT_BORDER_COLOR.
--                        (a string required)
-- notify_line_breakat  - the characters to split long lines at when using
--                        notice.notify(). expects a string.
-- notify_popup_title   - title of the notification popup window itself. defaults
--                        to NOTIFY_DEFAULT_TITLE. expects a string.
-- notify_top_margin    - top margin of the popup window. default to
--                        NOTIFY_DEFAULT_TOP_MARGIN. expects a number.
-- notify_right_margin  - right margin of the popup window. default to
--                        NOTIFY_DEFAULT_RIGHT_MARGIN. expects a number.
function M.setup(options)
    if options and type(options) ~= 'table' then
        error('notice.setup: \'options\' is the wrong type: received \''
              ..type(options)..'\', required: \'table\'')
    end
    -- use the same background as the main window
    local normal_hl = vim.api.nvim_get_hl_by_name('Normal', true)
    local border_hl = {}
    local notify_border_hl = {}

    for k,v in pairs(normal_hl) do
        border_hl[k] = v
        notify_border_hl[k] = v
    end

    border_hl.fg = options.border_color or POPUP_BORDER_COLOR
    notify_border_hl.fg = options.notify_border_color or NOTIFY_DEFAULT_BORDER_COLOR

    vim.api.nvim_set_hl(0, TEXT_HIGHLIGHT_GROUP_NAME, normal_hl)
    vim.api.nvim_set_hl(0, BORDER_HIGHLIGHT_GROUP_NAME, border_hl)
    vim.api.nvim_set_hl(0, NOTIFY_DEFAULT_BORDERHIGHLIGHT, notify_border_hl)

    CONFIG.notify_line_breakat = options.notify_line_breakat or NOTIFY_DEFAULT_LINE_BREAKAT
    CONFIG.notify_popup_title = options.notify_popup_title or NOTIFY_DEFAULT_TITLE
    CONFIG.notify_right_margin = options.notify_right_margin or NOTIFY_DEFAULT_RIGHT_MARGIN
    CONFIG.notify_top_margin = options.notify_top_margin or NOTIFY_DEFAULT_TOP_MARGIN
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

function M.notify(what, time)
    if not what then
        error("notice.notify: argument required: 'what' (a string or a list of strings)")
    end

    if type(what) ~= 'table' and type(what) ~= 'string' then
        error('notice.setup: \'what\' is the wrong type: received \''
              ..type(what)..'\', required: \'table\' or \'string\'')
    end

    if time and type(time) ~= 'number' then
        error('notice.setup: \'time\' is the wrong type: received \''
              ..type(time)..'\', required: \'number\'')
    end

    local width = NOTIFY_DEFAULT_WIDTH

    -- going into their own function cause of deep nesting issues
    local process_word = function(arg_tbl, word)
        arg_tbl.curr_len = arg_tbl.curr_len + #word

        local BREAKAT = CONFIG.notify_line_breakat
        local breakat = string.find(word, '(['..BREAKAT..'])')
        arg_tbl.last_breakat_index = breakat or arg_tbl.last_breakat_index

        table.insert(arg_tbl.line_array, word)

        if breakat then
            arg_tbl.last_breakat_word = #arg_tbl.line_array
        end

        local line
        local len
        if arg_tbl.curr_len >= arg_tbl.maxlen then
            if arg_tbl.last_breakat_word then
                -- there is a breakat character in a word we found.
                -- we are going to concatenate the string up until that word.
                -- then calculate the index of the breakat character and take
                -- the substring up until that character.
                breakat = arg_tbl.last_breakat_index
                local last_word = arg_tbl.last_breakat_word
                local fullstring = table.concat(arg_tbl.line_array, '', 1, last_word)
                local length_last_word = #arg_tbl.line_array[last_word]
                local loc_from_last = length_last_word - (length_last_word - breakat)

                line = string.sub(fullstring, 1, #fullstring - loc_from_last)
            else
                -- there is no breakat character, break the last word in
                -- two parts, the first part has to have maxlen-1 characters
                -- of the original string plus the NOTIFY_DEFAULT_WORDBREAK_CHAR
                -- character.
                local fullstring = table.concat(arg_tbl.line_array)
                line = string.sub(fullstring, 1, arg_tbl.maxlen-1)..NOTIFY_DEFAULT_WORDBREAK_CHAR
            end
            len = #line
        end

        return { line, len }
    end

    -- split the line into two or more lines, each at most maxlen of length.
    -- it tries to split the line at the nearest space or puctuation, if not
    -- able to find any then it uses a wordbreak char as the last character in the line
    local split_into_lines = function(line, maxlen)
        local lines = { }
        local lengths = { }
        local index = 1

        -- this removes '-' if the user specifies it with notify_line_breakat.
        local WORD = string.gsub('[-a-zA-Z0-9_]', CONFIG.notify_line_breakat, '')
        local PATTERN = '\\('..WORD..'\\+\\|\\s\\+\\|[[:punct:]]\\+\\)'
        while index < #line do
            local vars = {
                line_array = { },
                curr_len = 0,
                maxlen = maxlen,
                -- last_breakat_word = nil,
                -- last_breakat_index = nil
            }
            local res
            for word in re_gmatch(string.sub(line, index), PATTERN) do
                res = process_word(vars, word)
                if res[1] ~= nil then
                    break
                end
            end

            local line, len = table.unpack(res)
            if line == nil then
                -- reached the end of the string and there is some residue
                line = table.concat(vars.line_array)
                len = #line
            end

            table.insert(lines, line)
            table.insert(lengths, len)
            index = index + len
        end

        return { lines, lengths }
    end

    -- going into their own function cause of deep nesting issues
    local extend_list = function(lst_output, lst_input)
        for _, val in ipairs(lst_input) do
            table.insert(lst_output, val)
        end
    end

    -- going into their own function cause of deep nesting issues
    local copy_tbl_and_split_lines = function(what, maxlen)
        local lines = {}
        local lengths = {}
        for _,line in ipairs(what) do
            local len = #line
            if len > maxlen then
                local res = split_into_lines(line, maxlen)
                extend_list(lines, res[1])
                extend_list(lengths, res[2])
            else
                table.insert(lines, line)
                table.insert(lengths, len)
            end
        end

        return { lines, lengths }
    end

    -- the algorithm to center the lines is really simple:
    --
    -- - first split any line greater than maxlen into two or more lines.
    -- - calculate the alignment such that the left side has at most 1 character
    --   less than the right side.
    -- - fill up the lines after skipping the alignment characters.
    local center_lines = function(what, maxlen)
        local lines = {}
        local lengths = {}
        if type(what) == 'string' then
            if #what > maxlen then
                lines, lengths = table.unpack(split_into_lines(what, maxlen))
            else
                lines = {what}
                lengths = {#what}
            end
        elseif type(what) == 'table' then
            lines, lengths = table.unpack(copy_tbl_and_split_lines(what, maxlen))
        end

        -- the calculation to get the alignment is as follows:
        --
        -- - subtract from maxlen the length of the current string.
        -- - if the result is zero, then simply set the alignment to zero.
        -- - else:
        --     - divide by 2 and use math.ceil() to get the alignment.
        local alignments = {}
        for i, len in ipairs(lengths) do
            local rest = maxlen - len
            alignments[i] = rest == 0 and 0 or math.ceil(rest / 2)
        end

        local centered_lines = {}
        for i, line in ipairs(lines) do
            local spaces = string.rep(' ', alignments[i])
            centered_lines[i] = string.format('%s%s', spaces, line)
        end

        return centered_lines
    end

    local lines = center_lines(what, width)

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
        col = col,
        line = row,
        title = CONFIG.notify_popup_title,
        wrap = true,
        padding = NOTIFY_DEFAULT_PADDING,
        --time = time or NOTIFY_DEFAULT_TIME,
        border = true,
        borderhighlight = NOTIFY_DEFAULT_BORDERHIGHLIGHT,
        borderchars = BORDER_DEFAULT_CHARACTERS,
        highlight = TEXT_HIGHLIGHT_GROUP_NAME
    }

    return popup.create(lines, vim_options)
end

return M
