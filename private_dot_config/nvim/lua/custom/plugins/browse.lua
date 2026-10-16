-- Browse mode: read-only code browsing with a clickable file tree and click-to-follow.
-- Only active when started via the `browse` shell function (`nvim -R --cmd 'let g:browse=1'`).
if not vim.g.browse then return end

vim.pack.add { 'https://github.com/nvim-tree/nvim-tree.lua' }

local hint = 'enter/dbl-click def   bksp/right-click back   K hover   grr refs   gO symbols'
  .. '   spc-sf find   spc-sg grep   spc-sk keys   \\ tree   q quit'

-- File tree sidebar: single click opens a file or toggles a folder
local tree = require 'nvim-tree.api'
require('nvim-tree').setup {
  view = { width = 35 },
  renderer = { group_empty = true },
  on_attach = function(buf)
    tree.config.mappings.default_on_attach(buf)
    vim.keymap.set('n', '<LeftRelease>', function()
      local node = tree.tree.get_node_under_cursor()
      if node then tree.node.open.edit() end
    end, { buffer = buf, desc = 'Browse: open' })
    vim.keymap.set('n', 'q', '<Cmd>qa<CR>', { buffer = buf, desc = 'Browse: quit' })
  end,
}
vim.keymap.set('n', '\\', function() tree.tree.find_file { open = true, focus = true } end, { desc = 'Browse: reveal in tree' })

-- Every real file is unmodifiable and shows the key reference along the top
vim.api.nvim_create_autocmd('BufWinEnter', {
  group = vim.api.nvim_create_augroup('browse-readonly', { clear = true }),
  callback = function(args)
    if vim.bo[args.buf].buftype ~= '' then return end
    vim.bo[args.buf].modifiable = false
    vim.wo.winbar = '%#Comment# ' .. hint
  end,
})

-- Follow a definition: only where a language server is attached
local follow = '<Cmd>lua require("telescope.builtin").lsp_definitions()<CR>'
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('browse-lsp', { clear = true }),
  callback = function(args)
    local opts = { buffer = args.buf, desc = 'Browse: follow definition' }
    vim.keymap.set('n', '<2-LeftMouse>', follow, opts)
    vim.keymap.set('n', '<C-LeftMouse>', '<LeftMouse>' .. follow, opts)
    vim.keymap.set('n', '<CR>', follow, opts)
  end,
})

-- Back and forward through the jump list
vim.keymap.set('n', '<BS>', '<C-o>', { desc = 'Browse: back' })
vim.keymap.set('n', '<RightMouse>', '<C-o>', { desc = 'Browse: back' })
vim.keymap.set('n', '<X1Mouse>', '<C-o>', { desc = 'Browse: back' })
vim.keymap.set('n', '<X2Mouse>', '<C-i>', { desc = 'Browse: forward' })
vim.keymap.set('n', 'q', '<Cmd>qa<CR>', { desc = 'Browse: quit' })

-- Open the tree on start, with the README in the main window if there is one
vim.api.nvim_create_autocmd('VimEnter', {
  group = vim.api.nvim_create_augroup('browse-start', { clear = true }),
  nested = true,
  callback = function()
    if vim.fn.argc() == 0 and vim.uv.fs_stat 'README.md' then vim.cmd.edit 'README.md' end
    tree.tree.open { focus = false, find_file = true }
  end,
})

-- vim: ts=2 sts=2 sw=2 et
