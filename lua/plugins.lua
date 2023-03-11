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
            requires = { 'kyazdani42/nvim-web-devicons', opt = true }
        }

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
    local PARSER_INSTALL_DIR = NVIM_DATA_PATH..'/treesitter/parsers/',
    -- configuration to apply after loading treesitter
    require('nvim-treesitter.configs').setup {
            parser_install_dir = PARSER_INSTALL_DIR,
            -- a list of parsers to be available
            ensure_installed = { 'c', 'lua', 'vim', 'help', 'query',
          		       'bash', 'cmake', 'comment', 'cpp', 'css',
          		       'diff', 'html', 'json', 'make', 'regex',
          		       'typescript' },
            -- auto install missing parsers
            auto_install = true,
            -- enable syntax highlighting
            highlight = { enable = true },
            -- enable indentation for the = operator
            indent = { enable = true },
            -- enable incremental selection based on the named nodes from the grammar
            incremental_selection = {
                enable = true,
                keymaps = {
          	  init_selection = "gnn",
          	  node_incremental = "grn",
          	  scope_incremental = "grc",
          	  node_decremental = "grm",
          	}
                }
        }
        -- vim.opt.foldmethod     = 'expr'
        -- vim.opt.foldexpr       = 'nvim_treesitter#foldexpr()'
	-- only set to 'expr' if there isn't a modeline setting it to marker
        autocmd({'BufEnter','BufAdd','BufNew','BufNewFile','BufWinEnter'},
        {
          group = augroup('TS_FOLD_WORKAROUND', {}),
          callback = function()
	    if vim.opt.foldmethod:get() ~= 'marker' then
                vim.opt.foldlevel     = 3
                vim.opt.foldmethod     = 'expr'
                vim.opt.foldexpr       = 'nvim_treesitter#foldexpr()'
	    end
          end
        })
        vim.opt.runtimepath:append(PARSER_INSTALL_DIR)
    -- }}}

    -- website: https://github.com/neoclide/coc.nvim
    -- Coc (Conquer of Completions) {{{1
    use {'neoclide/coc.nvim', branch = 'release'}
    g.coc_global_extensions = {
        -- website: https://github.com/yuki-yano/fzf-preview.vim
        'coc-fzf-preview'
    }
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

    -- Lion.vim is a tool for aligning text by some character.
    -- website: https://github.com/tommcdo/vim-lion
    use 'tommcdo/vim-lion'

    -- I don't use the regular :FZF command of the fzf.vim plugin but instead
    -- use the fzf-preview, which is installed using coc.
    --
    -- website (lspfuzzy): https://github.com/ojroques/nvim-lspfuzzy
    -- website (FZF): https://github.com/junegunn/fzf
    -- website (FZF.vim): https://github.com/junegunn/fzf.vim
    use {'ojroques/nvim-lspfuzzy', requires = {{'junegunn/fzf'}, {'junegunn/fzf.vim'}}}

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

    -- remove all but the 'default' cheatsheets
    require('cheatsheet').setup {
        bundled_cheatsheets =  { 'default' },
        bundled_plugin_cheatsheets = false,
    }

    -- Automatically set up your configuration after cloning packer.nvim
    if packer_bootstrap then
       require('packer').sync()
    end

    require('lspfuzzy').setup { }
end)
