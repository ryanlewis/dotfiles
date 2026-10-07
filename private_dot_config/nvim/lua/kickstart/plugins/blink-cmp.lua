local function gh(repo) return 'https://github.com/' .. repo end

vim.pack.add { { src = gh 'saghen/blink.cmp', version = vim.version.range '1.*' } }
require('blink.cmp').setup {
  -- <c-y> accepts, <c-space> opens menu/docs, <c-e> hides, <c-k> toggles signature help
  keymap = { preset = 'default' },
  appearance = { nerd_font_variant = 'mono' },
  completion = {
    documentation = { auto_show = false, auto_show_delay_ms = 500 },
  },
  sources = {
    default = { 'lsp', 'path', 'snippets' },
  },
  fuzzy = { implementation = 'lua' },
  signature = { enabled = true },
}

-- vim: ts=2 sts=2 sw=2 et
