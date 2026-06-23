-- Colorscheme: vesper — the theme carried over from helix.
vim.pack.add { { src = 'https://github.com/datsfilipe/vesper.nvim' } }

require('vesper').setup {
  transparent = false,
  italics = {
    comments = true,
    keywords = false,
    functions = false,
    strings = false,
    variables = false,
  },
}

vim.cmd.colorscheme 'vesper'

-- vim: ts=2 sts=2 sw=2 et
