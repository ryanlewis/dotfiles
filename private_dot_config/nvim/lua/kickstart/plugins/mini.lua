local function gh(repo) return 'https://github.com/' .. repo end

-- [[ mini.nvim ]]
--  A collection of various small independent plugins/modules
vim.pack.add { gh 'nvim-mini/mini.nvim' }

-- If a nerd font is available, load the icons module for pretty icons in various plugins.
if vim.g.have_nerd_font then
  require('mini.icons').setup()
  -- Used for backwards compatibility with plugins that require `nvim-web-devicons` (e.g. telescope.nvim)
  MiniIcons.mock_nvim_web_devicons()
end

-- Better Around/Inside textobjects
--
-- Examples:
--  - va)  - [V]isually select [A]round [)]paren
--  - yiiq - [Y]ank [I]nside [I]+1 [Q]uote
--  - ci'  - [C]hange [I]nside [']quote
require('mini.ai').setup {
  -- NOTE: Avoid conflicts with the built-in incremental selection mappings on Neovim>=0.12 (see `:help treesitter-incremental-selection`)
  mappings = {
    around_next = 'aa',
    inside_next = 'ii',
  },
  n_lines = 500,
}

-- Add/delete/replace surroundings (brackets, quotes, etc.)
--
-- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
-- - sd'   - [S]urround [D]elete [']quotes
-- - sr)'  - [S]urround [R]eplace [)] [']
require('mini.surround').setup()

-- Autopairs — insert the matching ) ] } ' " as you type the opener (Helix did
-- this by default). Defaults only, so blink.cmp keeps ownership of <CR>.
require('mini.pairs').setup()

-- Toggle a bracketed list between one line and multi-line with `gS`.
require('mini.splitjoin').setup()

-- Show #rrggbb / #rgb colour codes with their actual colour inline (CSS/web).
local hipatterns = require 'mini.hipatterns'
hipatterns.setup {
  highlighters = {
    hex_color = hipatterns.gen_highlighter.hex_color(),
  },
}

-- Close a buffer without disturbing the window/split layout (plain :bd closes
-- the window too). Prompts on unsaved changes.
require('mini.bufremove').setup()
vim.keymap.set('n', '<leader>bd', function() require('mini.bufremove').delete() end, { desc = '[B]uffer [D]elete (keep layout)' })

-- Statusline (mini.statusline). The default sections already include mode, git,
-- diff, diagnostics, active LSP, filename, fileinfo, search count and location.
-- We override `content.active` only to keep cursor location as LINE:COLUMN and to
-- add a macro-recording badge (the one useful thing the default omits), so
-- `qq`-style recordings are visible while active.
local statusline = require 'mini.statusline'
statusline.setup {
  use_icons = vim.g.have_nerd_font,
  content = {
    active = function()
      local mode, mode_hl = statusline.section_mode { trunc_width = 120 }
      local git = statusline.section_git { trunc_width = 40 }
      local diff = statusline.section_diff { trunc_width = 75 }
      local diagnostics = statusline.section_diagnostics { trunc_width = 75 }
      local lsp = statusline.section_lsp { trunc_width = 75 }
      local filename = statusline.section_filename { trunc_width = 140 }
      local fileinfo = statusline.section_fileinfo { trunc_width = 120 }
      local search = statusline.section_searchcount { trunc_width = 75 }

      -- Empty unless a macro is recording, e.g. "REC @q" during `qq`.
      local rec = vim.fn.reg_recording()
      local recording = rec ~= '' and ('REC @' .. rec) or ''

      return statusline.combine_groups {
        { hl = mode_hl, strings = { mode } },
        { hl = 'MiniStatuslineDevinfo', strings = { git, diff, diagnostics, lsp } },
        '%<', -- Truncate from here when the window is narrow
        { hl = 'MiniStatuslineFilename', strings = { filename } },
        '%=', -- Right-align everything after this
        { hl = 'MiniStatuslineModeVisual', strings = { recording } },
        { hl = 'MiniStatuslineFileinfo', strings = { fileinfo } },
        { hl = mode_hl, strings = { search, '%2l:%-2v' } },
      }
    end,
  },
}

-- Buffer/tab bar across the top (mini.tabline — part of mini.nvim, no new deps).
--  Lists open buffers with icons; active buffer highlighted, `+` marks unsaved.
--  Sets showtabline=2, so the bar is always visible.
require('mini.tabline').setup()

-- ... and there is more!
--  Check out: https://github.com/nvim-mini/mini.nvim

-- vim: ts=2 sts=2 sw=2 et
