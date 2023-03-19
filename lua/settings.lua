-- vim:foldmethod=marker:foldlevel=0

local o = vim.opt

-- enables filetype detection
vim.cmd('filetype plugin indent on')

local M = {}

function M.setup()
    -- allow backspace over autoindent, line breaks,
    -- and make CTRL-W and CTRL-U to not stop at the start of insert
    o.backspace = 'indent,eol,nostop'

    -- backup options {{{1
    -- leave backup of files after it was written *extra safety*
    --o.backup = true
    -- set backup directories
    o.backupskip = '/tmp/*,COMMIT_EDITMSG'
    -- 1}}}

    -- disable bell alarm for these events. see :h 'belloff'
    o.belloff = 'backspace,cursor,complete,ctrlg,showmatch,wildmode,error'

    -- 'linebreak' {{{1

    -- 'linebreak' will use these characters
    o.breakat = '-.,?;:!'
    --  put a line break on long lines.
    --  purely visual, no <EOL> is inserted on the actual file.
    --  use 'wrapmargin' or 'textwidth' for that.
    o.linebreak = true
    -- visually indent lines wrapped by 'linebreak'
    o.breakindent = true
    o.showbreak = '~~ '
     -- display the 'showbreak' before additional indent
    o.breakindentopt = 'sbr'

    -- 1}}}
    -- insert a break after this much characters
    o.textwidth = 100

    -- when 'list' is enabled, use this character to display <EOL> characters.
    o.listchars = 'eol:¬'
    -- remove the command-line window
    o.cedit = ''
    -- avoid hit-enter prompts
    o.shortmess = 'aoOstTWIcF'
    -- for filetypes that enable 'cindent'
    -- read :h cinoptions-values if you want to understand this
    o.cinoptions = 'n-0.5sLs:0=2l1+2(2u2ksj1J1)10*200'
    -- highlight the line the cursor is at
    o.cursorline = true
    -- height of the window stays the same when 'equalalways' is on
    o.eadirection = 'hor'
    -- flash the screen on errors
    o.errorbells = true
    -- replace a audio bell for a visual bell
    -- I don't need to set this option since my terminal emulator (kitty)
    -- translate any bell requests to screen flashes automatically
    --o.visualbell = true
    -- hard <TAB>s are evil
    o.expandtab = true
    -- I like four space as indentation
    o.shiftwidth = 4
    -- set this number of spaces when <tab> is pressed
    o.tabstop = 4
    o.fillchars = 'fold:─,foldopen:⧆,foldclose:⊞,eob:⁋'
    -- show the fold column when there are folds in the window
    o.foldcolumn = 'auto:2'
    -- start with all folds opened
    -- I prefere to override this on a per-file basis using a modeline
    o.foldlevelstart = 99
    -- don't unload abandoned buffers
    o.hidden = true
    -- ignore case on pattern searches
    o.ignorecase = true
    -- don't ignore case if the pattern contains upper-cased letters
    o.smartcase = true
    -- show effects of :substitute, :smagic, and :snomagic
    --o.inccommand = 'split'
    -- see 'jumpotions'
    o.jumpoptions = 'stack'
    -- mouse support for all modes
    o.mouse = 'a'
    -- CTRL-A and CTRL-X increment/decrement octal values.
    -- 'unsigned' makes vim to always recognize number values as unsigned.
    o.nrformats:append('octal', 'unsigned')
    -- nice number in front of lines
    o.number = true
    o.relativenumber = true
    -- enables pseudo-transparency for the popup-menu
    o.pumblend = 10
    -- display a maximum of 10 items in the popup menu
    o.pumheight = 10
    -- always keep at least 3 lines of context before and after the cursor
    o.scrolloff = 3
    -- save options when in the Session.vim file
    -- I'd like to save terminal windows as well, but for some reason vim
    -- throws an error when I try it
    o.sessionoptions:append{'options', 'localoptions'}
    -- display signs in the number column
    o.signcolumn = 'number'
    -- remove the option to save variables that starts with uppercase letters.
    -- This was causing some issues with lists and dictionaries defined in lua
    -- files so I disabled it.
    o.shada:remove('!')
    -- briefly jump to the matched character (see :h 'matchpairs') when
    -- inserting a bracket
    o.showmatch = true
    -- no need to show the mode on the last line when we have the statusline
    o.showmode = false
    -- smart indenting when starting new line
    -- 'cindent' will override this
    o.smartindent = true
    -- behaviour of quickfix when jumping to errors
    o.switchbuf = {'useopen','usetab', 'newtab', 'uselast'}
    -- enable changing the title of the terminal window
    o.title = true
    -- write the swap to file after this many milliseconds without events
    o.updatetime = 300
    -- allow positioning the cursor past the end of the line in visual mode
    o.virtualedit = 'block'

    -- sets to start folding at at least 7 lines up
    o.foldminlines = 6
    -- don't nest folds too deeply or it will be a pain to reach inside
    o.foldnestmax = 2
    -- set these columns to be highlighted
    o.colorcolumn = {100}
    -- also scan the included files for ins-completion
    o.complete:append('i', 'd')
end

return M
