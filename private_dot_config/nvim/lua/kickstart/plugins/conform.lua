local function gh(repo) return 'https://github.com/' .. repo end

vim.pack.add { gh 'stevearc/conform.nvim' }
require('conform').setup {
  notify_on_error = false,
  -- No format-on-save: <leader>f formats on demand, so nothing reformats behind your back.
  default_format_opts = {
    lsp_format = 'fallback', -- use LSP formatting when no external formatter is configured
  },
  formatters_by_ft = {
    lua = { 'stylua' },
    javascript = { 'biome' },
    javascriptreact = { 'biome' },
    typescript = { 'biome' },
    typescriptreact = { 'biome' },
    json = { 'biome' },
    jsonc = { 'biome' },
    go = { 'gofmt' },
    python = { 'ruff_format' },
    rust = { 'rustfmt' },
  },
}

vim.keymap.set({ 'n', 'v' }, '<leader>f', function() require('conform').format { async = true } end, { desc = '[F]ormat buffer' })

-- vim: ts=2 sts=2 sw=2 et
