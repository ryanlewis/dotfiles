-- Markdown editing ergonomics (no plugins) — applied to markdown buffers only.
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'markdown',
  group = vim.api.nvim_create_augroup('custom-markdown', { clear = true }),
  callback = function(args)
    -- Prose-friendly: soft-wrap at word boundaries + spell check.
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
    vim.opt_local.spell = true
    -- The built-in markdown ftplugin omits r/o, so bullets don't continue on
    -- <CR> or o. Add them back (numbered auto-increment still needs a plugin).
    vim.opt_local.formatoptions:append 'ro'

    -- Toggle the first checkbox on the current line: [ ] <-> [x].
    vim.keymap.set('n', '<leader>tx', function()
      local line = vim.api.nvim_get_current_line()
      if line:find '%[ %]' then
        line = line:gsub('%[ %]', '[x]', 1)
      elseif line:find '%[[xX]%]' then
        line = line:gsub('%[[xX]%]', '[ ]', 1)
      end
      vim.api.nvim_set_current_line(line)
    end, { buffer = args.buf, desc = 'Toggle checkbox [x]' })
  end,
})

-- vim: ts=2 sts=2 sw=2 et
