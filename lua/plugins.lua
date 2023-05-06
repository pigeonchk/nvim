-- vim:foldmethod=marker:foldlevel=0

local fn = vim.fn   -- vim/user functions
local g = vim.g     -- vim global variables
local cmd = vim.cmd -- execute vim script commands
local autocmd  = vim.api.nvim_create_autocmd
local augroup  = vim.api.nvim_create_augroup

-- determine the path to the install packer plugin manager
local NVIM_DATA_PATH = fn.stdpath('data')
local RELATIVE_PACKER_PATH = '/site/pack/packer/start/packer.nvim'
local packer_install_path = NVIM_DATA_PATH..RELATIVE_PACKER_PATH

if fn.empty(fn.glob(packer_install_path)) > 0 then
    -- install packer if not installed yet
    -- the output is saved as a sort of flag because we need to sync() later on
    packer_bootstrap = fn.system({
            'git', 'clone', '--depth', '1',
            'https://github.com/wbthomason/packer.nvim',
            packer_install_path})
end

cmd('packadd packer.nvim')

require('packer').startup(function()
    -- website: https://github.com/wbthomason/packer.nvim
    use 'wbthomason/packer.nvim' -- this line always on top

    -- website: https://github.com/ellisonleao/gruvbox.nvim
    use { 'ellisonleao/gruvbox.nvim' }

    -- fast and beautiful statusline
    -- website: https://github.com/nvim-lualine/lualine.nvim
    use { 'nvim-lualine/lualine.nvim',
            requires = { 'nvim-tree/nvim-web-devicons', opt = true }
        }

    use { 'rcarriga/nvim-notify' }

    -- treesitter is used for a lot of things like:
    --   * syntax highlighting
    --   * folding
    --   * indentation
    -- website: https://github.com/nvim-treesitter/nvim-treesitter
    -- treesitter {{{1
    use { 'nvim-treesitter/nvim-treesitter',
        -- NOTE: recommended by the wiki to run post-update/install
        run = function()
            local ts_update = require('nvim-treesitter.install').update({ with_sync = true })
            ts_update()
        end,
    }
    -- plugins for treesitter.nvim

    -- Highlight definitions, navigation and rename powered by nvim-treesitter.
    -- website: https://github.com/nvim-treesitter/nvim-treesitter-refactor
    use { 'nvim-treesitter/nvim-treesitter-refactor' }
    -- Always show current function context
    -- website: https://github.com/nvim-treesitter/nvim-treesitter-context.
    use { 'nvim-treesitter/nvim-treesitter-context' }
    -- Rainbow parentheses powered by tree-sitter.
    -- https://github.com/HiPhish/nvim-ts-rainbow2
    use { 'HiPhish/nvim-ts-rainbow2' }

    -- }}}

    -- website: https://github.com/neoclide/coc.nvim
    -- Coc (Conquer of Completions) {{{1
    use {'neoclide/coc.nvim', branch = 'release'}
    g.coc_global_extensions = {
        'coc-json',
        'coc-clangd',
        'coc-calc',
        'coc-tsserver',
        -- 'coc-eslint',
        'coc-htmlhint',
        'coc-diagnostic',
        'coc-glslx',
        'coc-eslint',
        -- website: https://github.com/yuki-yano/fzf-preview.vim
        'coc-fzf-preview',
        'coc-lua',
    }

    -- }}}

    use { 'mrded/nvim-lsp-notify', config = function()
        require('lsp-notify').setup({})
    end}

    -- highlight, navigate, and operate on sets of matching text.
    -- website: https://github.com/andymass/vim-matchup/
    use { 'andymass/vim-matchup', setup = function()
        -- may set any options here
        vim.g.matchup_matchparen_offscreen = { method = "popup" }
        -- don't match keywords in strings and comments
        vim.g.matchup_delim_noskips = 1
        -- delays highlighting for a short time to wait if the cursor continue moving
        vim.g.matchup_matchparen_deferred = 1
        end
    }

    -- Syntax-Tree-Surfer {{{1
    -- Navigate around your document based on Treesitter's abstract Syntax Tree
    -- website: https://github.com/ziontee113/syntax-tree-surfer
    --
    -- disabled for now because I can't seem to make it to work.
    -- I may go back to try it after some time, idk
    use { 'ziontee113/syntax-tree-surfer' , disable = true}
    -- }}}

    -- remove trailing whitespace
    -- the command is :[RANGE]FixWhitespace
    -- or you can use select mode to select some text
    --
    -- website: https://github.com/bronson/vim-trailing-whitespace
    use 'bronson/vim-trailing-whitespace'

    -- small plugin that provides easy way to surround words with parentheses,
    -- brackets, quotes, etc.
    -- website: https://github.com/tpope/vim-surround
    use 'tpope/vim-surround'
    g.lion_squeeze_spaces = 1

    -- Lion.vim is a tool for aligning text by some character.
    -- website: https://github.com/tommcdo/vim-lion
    use 'tommcdo/vim-lion'

    -- helps me keep track of all my bindings because I have a very bad memory
    -- website: https://github.com/sudormrfbin/cheatsheet.nvim
    use { 'sudormrfbin/cheatsheet.nvim',
          requires = {
            -- website: https://github.com/nvim-telescope/telescope.nvim
            {'nvim-telescope/telescope.nvim'},
            -- website: https://github.com/nvim-lua/popup.nvim
            {'nvim-lua/popup.nvim'},
            -- website: https://github.com/nvim-lua/plenary.nvim
            {'nvim-lua/plenary.nvim'},
          }
    }

    use { 'lukas-reineke/virt-column.nvim' }

    -- Automatically set up your configuration after cloning packer.nvim
    if packer_bootstrap then
       require('packer').sync()
    end
end)

return function()
    vim.notify = require('notify')

    -- Treesitter {{{
    local PARSER_INSTALL_DIR = NVIM_DATA_PATH..'/treesitter/parsers/'
    -- configuration to apply after loading treesitter
    require('nvim-treesitter.configs').setup {
        parser_install_dir = PARSER_INSTALL_DIR,

        -- a list of parsers to be available
        --[[
        ensure_installed = { 'c', 'lua', 'vim', 'help', 'query',
        	       'bash', 'cmake', 'comment', 'cpp', 'css',
        	       'diff', 'html', 'json', 'make', 'regex',
        	       'typescript' },
        --]]
        auto_install = true,
        -- enable syntax highlighting
        highlight = { enable = true },
        -- enable indentation for the = operator
        indent = { enable = true },
        -- enable incremental selection based on the named nodes from the grammar
        incremental_selection = { enable = false },
        refactor = {
            highlight_definitions = { enable = true, clear_on_cursor_move = true },
            smart_rename = { enable = true, keymaps = { smart_rename = "grr" } },
        },
        rainbow = {
            enable = true,
            disable = {},
            query = 'rainbow-parens',
            strategy = require('ts-rainbow.strategy.global')
        },
        matchup = {
            enable = true,
        },
    }

    require('treesitter-context').setup{
        -- Enable this plugin (Can be enabled/disabled later via commands)
        enable = true,
        -- How many lines the window should span. Values <= 0 mean no limit.
        max_lines = 5,
        -- Minimum editor window height to enable context. Values <= 0 mean no limit.
        min_window_height = 0,
        line_numbers = true,
        -- Maximum number of lines to collapse for a single context line
        multiline_threshold = 20,
        -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
        trim_scope = 'outer',
        -- Line used to calculate context. Choices: 'cursor', 'topline'
        mode = 'cursor',
        -- Separator between context and content. Should be a single character
        -- string, like '-'. When separator is set, the context will only show
        -- up when there are at least 2 lines above cursorline.
        separator = '─',
        -- The Z-index of the context window
        zindex = 20,
    }

    -- vim.opt.foldmethod     = 'expr'
    -- vim.opt.foldexpr       = 'nvim_treesitter#foldexpr()'
	-- only set to 'expr' if there isn't a modeline setting it to marker
    autocmd({'BufEnter','BufAdd','BufNew','BufNewFile','BufWinEnter'},
    {
      group = augroup('TS_FOLD_WORKAROUND', {}),
      callback = function()
	if vim.opt.foldmethod:get() ~= 'marker' then
        vim.opt.foldlevel  = 3
        vim.opt.foldmethod = 'expr'
        vim.opt.foldexpr   = 'nvim_treesitter#foldexpr()'
	end
      end
    })
    vim.opt.runtimepath:append(PARSER_INSTALL_DIR)

    -- }}}

    -- remove all but the 'default' cheatsheets
    require('cheatsheet').setup {
        bundled_cheatsheets =  { 'default' },
        bundled_plugin_cheatsheets = false,
    }

    require('virt-column').setup()
end
