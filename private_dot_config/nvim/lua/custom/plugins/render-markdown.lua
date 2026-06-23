-- In-buffer markdown rendering: styled headings, list/checkbox icons, boxed code
-- blocks, aligned tables, and > [!NOTE] callouts. Renders in normal mode and
-- un-renders the line under the cursor, so editing stays plain text.
-- Manages 'conceallevel' itself, so we don't set it in the markdown ftplugin.
vim.pack.add { { src = 'https://github.com/MeanderingProgrammer/render-markdown.nvim' } }

require('render-markdown').setup {
  code = {
    -- Background hugs the code as a card instead of full-window grey slabs.
    width = 'block',
    min_width = 45,
    left_pad = 2,
    right_pad = 2,
  },
  -- 'trimmed' shaves excess column padding so tables stay as narrow as possible.
  -- A table whose widest row still exceeds the window can't render as a grid while
  -- wrapped — use <leader>tW to toggle wrap off and scroll horizontally for those.
  pipe_table = { cell = 'trimmed' },
}

-- Recolour code highlights to suit vesper. The defaults link to ColorColumn (a
-- harsh light grey here) and inline code inherits the same slab, speckling prose.
-- render-markdown sets its groups with `default = true`, so these explicit sets
-- win; the ColorScheme autocmd re-applies them whenever vesper is (re)loaded.
local function vesper_code_colors()
  if vim.g.colors_name ~= 'vesper' then return end
  vim.api.nvim_set_hl(0, 'RenderMarkdownCode', { bg = '#1c1c1c' }) -- subtle block card
  vim.api.nvim_set_hl(0, 'RenderMarkdownCodeInline', { fg = '#FFCFA8' }) -- warm orange, no box
end
vim.api.nvim_create_autocmd('ColorScheme', {
  group = vim.api.nvim_create_augroup('render-markdown-vesper', { clear = true }),
  callback = vesper_code_colors,
})
vesper_code_colors()

-- vim: ts=2 sts=2 sw=2 et
