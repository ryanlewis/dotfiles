-- Obsidian vault integration for ~/dev/notes.
--  render-markdown.nvim owns in-buffer rendering, so obsidian's built-in `ui` is
--  disabled to avoid double-rendering (and its conceallevel warning).
--  The completion engine (blink.cmp) is auto-detected — no extra config needed.
vim.pack.add { { src = 'https://github.com/obsidian-nvim/obsidian.nvim', version = vim.version.range '*' } }

require('obsidian').setup {
  legacy_commands = false, -- use the `:Obsidian <subcommand>` form
  workspaces = {
    { name = 'notes', path = '~/dev/notes' },
  },
  ui = { enable = false }, -- render-markdown.nvim handles rendering
  picker = { name = 'telescope.nvim' },
  -- Map `gf` to follow [[wikilinks]], but only inside vault notes.
  callbacks = {
    enter_note = function()
      vim.keymap.set('n', 'gf', '<cmd>Obsidian follow_link<cr>', { buffer = true, desc = 'Obsidian: follow link' })
    end,
  },
}

-- Vault commands (obsidian resolves the active workspace).
vim.keymap.set('n', '<leader>oo', '<cmd>Obsidian quick_switch<cr>', { desc = '[O]bsidian: [O]pen / switch note' })
vim.keymap.set('n', '<leader>os', '<cmd>Obsidian search<cr>', { desc = '[O]bsidian: [S]earch (grep)' })
vim.keymap.set('n', '<leader>on', '<cmd>Obsidian new<cr>', { desc = '[O]bsidian: [N]ew note' })
vim.keymap.set('n', '<leader>ot', '<cmd>Obsidian today<cr>', { desc = "[O]bsidian: [T]oday's daily note" })
vim.keymap.set('n', '<leader>ob', '<cmd>Obsidian backlinks<cr>', { desc = '[O]bsidian: [B]acklinks' })

-- vim: ts=2 sts=2 sw=2 et
