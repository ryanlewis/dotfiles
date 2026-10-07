vim.pack.add { 'https://github.com/folke/which-key.nvim' }
require('which-key').setup {
  -- Non-zero so the menu only appears when you pause on a prefix
  delay = 300,
  icons = { mappings = vim.g.have_nerd_font },
  spec = {
    { '<leader>s', group = '[S]earch', mode = { 'n', 'v' } },
    { '<leader>b', group = '[B]uffer' },
    { '<leader>o', group = '[O]bsidian' },
    { '<leader>t', group = '[T]oggle' },
    { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } },
    { 'gr', group = 'LSP Actions', mode = { 'n' } },
  },
}

-- vim: ts=2 sts=2 sw=2 et
