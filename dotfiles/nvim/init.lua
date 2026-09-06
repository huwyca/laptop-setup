-- ============================================================================
-- Neovim config (rewritten 2026-05-04 for nvim 0.12+).
-- Targets modern APIs throughout: vim.lsp.config/enable, treesitter `main`
-- branch, blink.cmp for completion, native commenting, vim.snippet.
-- ============================================================================

-- Leader keys must be set before plugins load.
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- ---------------------------------------------------------------------------
-- Bootstrap lazy.nvim
-- ---------------------------------------------------------------------------
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local out = vim.fn.system({
    'git', 'clone', '--filter=blob:none', '--branch=stable',
    'https://github.com/folke/lazy.nvim.git', lazypath,
  })
  if vim.v.shell_error ~= 0 then
    error('Failed to clone lazy.nvim:\n' .. out)
  end
end
vim.opt.rtp:prepend(lazypath)

-- ---------------------------------------------------------------------------
-- Options
-- ---------------------------------------------------------------------------
vim.o.hlsearch = false
vim.o.number = true
vim.o.mouse = 'a'
vim.o.clipboard = 'unnamedplus'
vim.o.breakindent = true
vim.o.undofile = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.signcolumn = 'yes'
vim.o.updatetime = 250
vim.o.timeoutlen = 300
vim.o.completeopt = 'menu,menuone,noselect'
vim.o.termguicolors = true

-- ---------------------------------------------------------------------------
-- Basic keymaps
-- ---------------------------------------------------------------------------
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })
vim.keymap.set('i', 'jj', '<Esc>', { noremap = true })
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Diagnostics
vim.keymap.set('n', '[d', function() vim.diagnostic.jump({ count = -1 }) end, { desc = 'Previous diagnostic' })
vim.keymap.set('n', ']d', function() vim.diagnostic.jump({ count = 1 }) end, { desc = 'Next diagnostic' })
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Open diagnostic float' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Diagnostics to loclist' })

-- Highlight on yank (uses vim.hl, the 0.11+ replacement for vim.highlight).
vim.api.nvim_create_autocmd('TextYankPost', {
  group = vim.api.nvim_create_augroup('YankHighlight', { clear = true }),
  callback = function() vim.hl.on_yank() end,
})

-- ---------------------------------------------------------------------------
-- Plugins
-- ---------------------------------------------------------------------------
require('lazy').setup({
  -- Git
  'tpope/vim-fugitive',
  'tpope/vim-rhubarb',

  -- Auto-detect indentation per file.
  'tpope/vim-sleuth',

  -- Colorscheme
  {
    'navarasu/onedark.nvim',
    priority = 1000,
    config = function() vim.cmd.colorscheme('onedark') end,
  },

  -- Statusline
  {
    'nvim-lualine/lualine.nvim',
    opts = {
      options = {
        icons_enabled = false,
        theme = 'onedark',
        component_separators = '|',
        section_separators = '',
      },
      sections = { lualine_c = { { 'filename', path = 4 } } },
      inactive_sections = { lualine_c = { { 'filename', path = 4 } } },
    },
  },

  -- Indent guides
  {
    'lukas-reineke/indent-blankline.nvim',
    main = 'ibl',
    opts = { indent = { char = '┊' } },
  },

  -- Git signs in gutter
  {
    'lewis6991/gitsigns.nvim',
    opts = {
      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns
        vim.keymap.set('n', '<leader>hp', gs.preview_hunk, { buffer = bufnr, desc = 'Preview git hunk' })
        vim.keymap.set({ 'n', 'v' }, ']c', function()
          if vim.wo.diff then return ']c' end
          vim.schedule(function() gs.next_hunk() end)
          return '<Ignore>'
        end, { expr = true, buffer = bufnr, desc = 'Next git hunk' })
        vim.keymap.set({ 'n', 'v' }, '[c', function()
          if vim.wo.diff then return '[c' end
          vim.schedule(function() gs.prev_hunk() end)
          return '<Ignore>'
        end, { expr = true, buffer = bufnr, desc = 'Previous git hunk' })
      end,
    },
  },

  -- Pending-keybind helper
  { 'folke/which-key.nvim', event = 'VeryLazy', opts = {} },

  -- Fuzzy finder
  {
    'nvim-telescope/telescope.nvim',
    branch = 'master',
    dependencies = {
      'nvim-lua/plenary.nvim',
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'make',
        cond = function() return vim.fn.executable('make') == 1 end,
      },
    },
    config = function()
      local telescope = require('telescope')
      telescope.setup({
        defaults = {
          mappings = { i = { ['<C-u>'] = false, ['<C-d>'] = false } },
        },
      })
      pcall(telescope.load_extension, 'fzf')

      local builtin = require('telescope.builtin')
      vim.keymap.set('n', '<leader>?', builtin.oldfiles, { desc = '[?] Recently opened files' })
      vim.keymap.set('n', '<leader><space>', builtin.buffers, { desc = '[ ] Buffers' })
      vim.keymap.set('n', '<leader>/', function()
        builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown({
          winblend = 10,
          previewer = false,
        }))
      end, { desc = '[/] Fuzzy find in buffer' })
      vim.keymap.set('n', '<leader>gf', builtin.git_files, { desc = '[G]it [F]iles' })
      vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
      vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
      vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch [W]ord' })
      vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
      vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
      vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
    end,
  },

  -- Treesitter (main branch — modern API).
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    lazy = false,
    build = ':TSUpdate',
    config = function()
      require('nvim-treesitter').install({
        'c', 'cpp', 'go', 'lua', 'python', 'rust',
        'tsx', 'javascript', 'typescript',
        'html', 'css', 'json', 'yaml', 'markdown', 'markdown_inline',
        'vimdoc', 'vim', 'bash', 'query',
      })

      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('treesitter-start', { clear = true }),
        callback = function(ev)
          local lang = vim.treesitter.language.get_lang(vim.bo[ev.buf].filetype)
          if lang and pcall(vim.treesitter.start, ev.buf, lang) then
            vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })
    end,
  },

  -- Treesitter textobjects (main branch — modern API).
  {
    'nvim-treesitter/nvim-treesitter-textobjects',
    branch = 'main',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    event = { 'BufReadPost', 'BufNewFile' },
    config = function()
      require('nvim-treesitter-textobjects').setup({
        select = { lookahead = true },
        move = { set_jumps = true },
      })

      local select = require('nvim-treesitter-textobjects.select')
      local move = require('nvim-treesitter-textobjects.move')
      local swap = require('nvim-treesitter-textobjects.swap')

      local function map_select(key, query)
        vim.keymap.set({ 'x', 'o' }, key, function()
          select.select_textobject(query, 'textobjects')
        end, { desc = 'Select ' .. query })
      end
      map_select('aa', '@parameter.outer')
      map_select('ia', '@parameter.inner')
      map_select('af', '@function.outer')
      map_select('if', '@function.inner')
      map_select('ac', '@class.outer')
      map_select('ic', '@class.inner')

      local function map_move(modes, key, fn, query)
        vim.keymap.set(modes, key, function() fn(query, 'textobjects') end,
          { desc = key .. ' ' .. query })
      end
      map_move({ 'n', 'x', 'o' }, ']m', move.goto_next_start, '@function.outer')
      map_move({ 'n', 'x', 'o' }, ']]', move.goto_next_start, '@class.outer')
      map_move({ 'n', 'x', 'o' }, ']M', move.goto_next_end, '@function.outer')
      map_move({ 'n', 'x', 'o' }, '][', move.goto_next_end, '@class.outer')
      map_move({ 'n', 'x', 'o' }, '[m', move.goto_previous_start, '@function.outer')
      map_move({ 'n', 'x', 'o' }, '[[', move.goto_previous_start, '@class.outer')
      map_move({ 'n', 'x', 'o' }, '[M', move.goto_previous_end, '@function.outer')
      map_move({ 'n', 'x', 'o' }, '[]', move.goto_previous_end, '@class.outer')

      vim.keymap.set('n', '<leader>a', function() swap.swap_next('@parameter.inner') end,
        { desc = 'Swap with next param' })
      vim.keymap.set('n', '<leader>A', function() swap.swap_previous('@parameter.inner') end,
        { desc = 'Swap with previous param' })
    end,
  },

  -- Mason: LSP server installer.
  { 'mason-org/mason.nvim', opts = {} },

  -- LSP
  {
    'neovim/nvim-lspconfig',
    dependencies = {
      'mason-org/mason.nvim',
      'mason-org/mason-lspconfig.nvim',
      { 'j-hui/fidget.nvim', opts = {} },
      { 'folke/lazydev.nvim', ft = 'lua', opts = {} },
    },
    config = function()
      -- LSP keymaps attach per buffer when a client connects.
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
        callback = function(event)
          local map = function(keys, func, desc, mode)
            vim.keymap.set(mode or 'n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
          end
          local builtin = require('telescope.builtin')

          map('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
          map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction', { 'n', 'x' })
          map('gd', vim.lsp.buf.definition, '[G]oto [D]efinition')
          map('gr', builtin.lsp_references, '[G]oto [R]eferences')
          map('gI', builtin.lsp_implementations, '[G]oto [I]mplementation')
          map('<leader>D', vim.lsp.buf.type_definition, 'Type [D]efinition')
          map('<leader>ds', builtin.lsp_document_symbols, '[D]ocument [S]ymbols')
          map('<leader>ws', builtin.lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')
          map('K', vim.lsp.buf.hover, 'Hover Documentation')
          map('<C-k>', vim.lsp.buf.signature_help, 'Signature Help')
          map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
          map('<leader>wa', vim.lsp.buf.add_workspace_folder, '[W]orkspace [A]dd Folder')
          map('<leader>wr', vim.lsp.buf.remove_workspace_folder, '[W]orkspace [R]emove Folder')
          map('<leader>wl', function()
            print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
          end, '[W]orkspace [L]ist Folders')

          vim.api.nvim_buf_create_user_command(event.buf, 'Format', function()
            vim.lsp.buf.format()
          end, { desc = 'Format current buffer with LSP' })
        end,
      })

      local servers = {
        tsgo = {},
        angularls = {},
        rust_analyzer = {},
        pyright = {},
        html = {},
        cssls = {},
        lua_ls = {
          settings = {
            Lua = {
              workspace = { checkThirdParty = false },
              telemetry = { enable = false },
            },
          },
        },
      }

      -- tsgo ships in workspace node_modules and isn't a Mason package.
      local non_mason = { tsgo = true }
      local mason_servers = {}
      for name in pairs(servers) do
        if not non_mason[name] then table.insert(mason_servers, name) end
      end

      require('mason-lspconfig').setup({
        ensure_installed = mason_servers,
        automatic_enable = false,
      })

      -- Broadcast blink.cmp's extended capabilities to all LSP servers.
      vim.lsp.config('*', {
        capabilities = require('blink.cmp').get_lsp_capabilities(),
      })

      for name, config in pairs(servers) do
        vim.lsp.config(name, config)
        vim.lsp.enable(name)
      end
    end,
  },

  -- Completion
  {
    'saghen/blink.cmp',
    version = '*',
    dependencies = { 'rafamadriz/friendly-snippets' },
    opts = {
      keymap = { preset = 'default' },
      appearance = { nerd_font_variant = 'mono' },
      completion = {
        documentation = { auto_show = true, auto_show_delay_ms = 200 },
      },
      sources = {
        default = { 'lsp', 'path', 'snippets', 'buffer' },
      },
      signature = { enabled = true },
    },
    opts_extend = { 'sources.default' },
  },
}, {
  -- Lazy.nvim options
  ui = { border = 'rounded' },
})

-- The line beneath this is called `modeline`. See `:help modeline`.
-- vim: ts=2 sts=2 sw=2 et
