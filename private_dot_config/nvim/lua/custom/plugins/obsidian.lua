-- Obsidian vault integration for ~/dev/notes.
--  render-markdown.nvim owns in-buffer rendering, so obsidian's built-in `ui` is
--  disabled to avoid double-rendering (and its conceallevel warning).
--  The completion engine (blink.cmp) is auto-detected — no extra config needed.
vim.pack.add { { src = 'https://github.com/obsidian-nvim/obsidian.nvim', version = vim.version.range '*' } }

local vault = vim.fs.normalize '~/dev/notes'

-- Set up on first use rather than at startup: nvim is $EDITOR, so most launches
-- (commit messages, config edits) never touch the vault.
local loaded = false
local function load()
  if loaded then return end
  loaded = true
  require('obsidian').setup {
    legacy_commands = false, -- use the `:Obsidian <subcommand>` form
    workspaces = {
      { name = 'notes', path = vault },
    },
    ui = { enable = false }, -- render-markdown.nvim handles rendering
    picker = { name = 'telescope.nvim' },
    -- The vault manages its own frontmatter; don't stamp id/aliases/tags on save.
    frontmatter = { enabled = false },
    -- New notes land in inbox/ (the vault's capture folder), named by their title.
    notes_subdir = 'inbox',
    new_notes_location = 'notes_subdir',
    note_id_func = function(title)
      if title == nil or vim.trim(title) == '' then return require('obsidian.builtin').zettel_id() end
      return (title:gsub('[/\\:]', '-'))
    end,
    -- Match the Obsidian app's daily-notes settings (.obsidian/daily-notes.json).
    daily_notes = {
      folder = 'Daily Notes',
      date_format = 'YYYY/MM/DD',
      template = 'daily-note.md',
      default_tags = {},
    },
    templates = { folder = 'templates' },
    -- Map `gf` to follow [[wikilinks]], but only inside vault notes.
    callbacks = {
      enter_note = function() vim.keymap.set('n', 'gf', '<cmd>Obsidian follow_link<cr>', { buffer = true, desc = 'Obsidian: follow link' }) end,
    },
  }
end

local function in_vault(path) return path ~= '' and vim.fs.relpath(vault, vim.fs.normalize(path)) ~= nil end

vim.api.nvim_create_autocmd({ 'BufReadPre', 'BufNewFile' }, {
  group = vim.api.nvim_create_augroup('custom-obsidian-load', { clear = true }),
  pattern = '*.md',
  callback = function(args)
    if in_vault(args.file) then load() end
  end,
})

-- Vault commands (obsidian resolves the active workspace).
local function cmd(sub)
  return function()
    load()
    vim.cmd('Obsidian ' .. sub)
  end
end
vim.keymap.set('n', '<leader>oo', cmd 'quick_switch', { desc = '[O]bsidian: [O]pen / switch note' })
vim.keymap.set('n', '<leader>os', cmd 'search', { desc = '[O]bsidian: [S]earch (grep)' })
vim.keymap.set('n', '<leader>on', cmd 'new', { desc = '[O]bsidian: [N]ew note' })
vim.keymap.set('n', '<leader>ot', cmd 'today', { desc = "[O]bsidian: [T]oday's daily note" })
vim.keymap.set('n', '<leader>ob', cmd 'backlinks', { desc = '[O]bsidian: [B]acklinks' })

-- vim: ts=2 sts=2 sw=2 et
