local function gh(repo) return 'https://github.com/' .. repo end

vim.pack.add { { src = gh 'nvim-treesitter/nvim-treesitter', version = 'main' } }

local parsers = {
  'bash',
  'c',
  'diff',
  'html',
  'lua',
  'luadoc',
  'markdown',
  'markdown_inline',
  'query',
  'vim',
  'vimdoc',
  -- web — css/javascript also inject into HTML <style> / <script> blocks
  'css',
  'javascript',
  'typescript',
  'tsx',
  'json',
  'yaml',
  -- languages I work in
  'go',
  'python',
}
require('nvim-treesitter').install(parsers)

---@param buf integer
---@param language string
local function treesitter_try_attach(buf, language)
  if not vim.treesitter.language.add(language) then return end
  vim.treesitter.start(buf, language)

  -- Treesitter indent only where the language ships an indents query
  if vim.treesitter.query.get(language, 'indents') ~= nil then vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()" end
end

local available_parsers = require('nvim-treesitter').get_available()
vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('kickstart-treesitter', { clear = true }),
  callback = function(args)
    local buf, filetype = args.buf, args.match

    local language = vim.treesitter.language.get_lang(filetype)
    if not language then return end

    local installed_parsers = require('nvim-treesitter').get_installed 'parsers'

    if vim.tbl_contains(installed_parsers, language) then
      treesitter_try_attach(buf, language)
    elseif vim.tbl_contains(available_parsers, language) then
      -- Install the parser, then attach once it's ready (the buffer may no longer be current)
      require('nvim-treesitter').install(language):await(function()
        if vim.api.nvim_buf_is_valid(buf) then treesitter_try_attach(buf, language) end
      end)
    else
      -- The parser may exist outside nvim-treesitter's registry
      treesitter_try_attach(buf, language)
    end
  end,
})

-- vim: ts=2 sts=2 sw=2 et
