local function gh(repo) return 'https://github.com/' .. repo end

vim.pack.add { gh 'j-hui/fidget.nvim' }
require('fidget').setup {}

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
  callback = function(event)
    local map = function(keys, func, desc, mode)
      mode = mode or 'n'
      vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
    end

    map('grn', vim.lsp.buf.rename, '[R]e[n]ame')
    map('gra', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })
    map('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration') -- declaration, not definition (e.g. a C header)

    -- Highlight references to the word under the cursor while it rests there
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if client and client:supports_method('textDocument/documentHighlight', event.buf) then
      local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
      vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
        buffer = event.buf,
        group = highlight_augroup,
        callback = vim.lsp.buf.document_highlight,
      })

      vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
        buffer = event.buf,
        group = highlight_augroup,
        callback = vim.lsp.buf.clear_references,
      })

      vim.api.nvim_create_autocmd('LspDetach', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
        callback = function(event2)
          vim.lsp.buf.clear_references()
          vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
        end,
      })
    end

    if client and client:supports_method('textDocument/inlayHint', event.buf) then
      map('<leader>th', function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf }) end, '[T]oggle Inlay [H]ints')
    end
  end,
})

-- Eager servers: Mason-installed on startup and always enabled
---@type table<string, vim.lsp.Config>
local servers = {
  ts_ls = {}, -- TypeScript / JavaScript (also covers Cloudflare Workers)

  lua_ls = {
    on_init = function(client)
      client.server_capabilities.documentFormattingProvider = false -- stylua formats

      if client.workspace_folders then
        local path = client.workspace_folders[1].name
        if path ~= vim.fn.stdpath 'config' and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc')) then return end
      end

      client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
        runtime = {
          version = 'LuaJIT',
          path = { 'lua/?.lua', 'lua/?/init.lua' },
        },
        workspace = {
          checkThirdParty = false,
          -- The whole runtime is slow to index (nvim-lspconfig#3189), but gives full plugin types
          library = vim.tbl_extend('force', vim.api.nvim_get_runtime_file('', true), {
            '${3rd}/luv/library',
            '${3rd}/busted/library',
          }),
        },
      })
    end,
    ---@type lspconfig.settings.lua_ls
    settings = {
      Lua = {
        format = { enable = false }, -- stylua formats
      },
    },
  },
}

vim.pack.add {
  gh 'neovim/nvim-lspconfig',
  gh 'mason-org/mason.nvim',
  gh 'mason-org/mason-lspconfig.nvim',
  gh 'WhoIsSethDaniel/mason-tool-installer.nvim',
}

require('mason').setup {}

local ensure_installed = vim.tbl_keys(servers or {})
vim.list_extend(ensure_installed, {
  'stylua', -- Lua formatter (used by conform; not on PATH otherwise)
  'ruff', -- Python linter + formatter (conform's ruff_format; not on PATH otherwise)
})

require('mason-tool-installer').setup { ensure_installed = ensure_installed }

for name, server in pairs(servers) do
  vim.lsp.config(name, server)
  vim.lsp.enable(name)
end

-- Biome attaches only in projects with a biome.json; it's on PATH (or node_modules) already.
vim.lsp.enable 'biome'

vim.pack.add { gh 'b0o/SchemaStore.nvim' }

-- Schema validation for JSON/YAML (workflows, renovate.json, package.json, …).
--  The catalogue loads in before_init, so it costs nothing until a server starts.
vim.lsp.config('jsonls', {
  before_init = function(_, config)
    config.settings = vim.tbl_deep_extend('force', config.settings or {}, {
      json = { schemas = require('schemastore').json.schemas(), validate = { enable = true } },
    })
  end,
})
vim.lsp.config('yamlls', {
  before_init = function(_, config)
    config.settings = vim.tbl_deep_extend('force', config.settings or {}, {
      yaml = { schemaStore = { enable = false, url = '' }, schemas = require('schemastore').yaml.schemas() },
    })
  end,
})

-- Lint only Go repos that configure golangci-lint.
vim.lsp.config('golangci_lint_ls', {
  root_markers = { '.golangci.yml', '.golangci.yaml', '.golangci.toml', '.golangci.json' },
  workspace_required = true,
})

-- On-demand language servers: rather than eager-installing these on startup, the
-- server is Mason-installed and enabled the first time you open a matching file.
local on_demand_servers = {
  go = { 'gopls', 'golangci_lint_ls' },
  python = { 'pyright' },
  rust = { 'rust_analyzer' },
  sh = { 'bashls' },
  bash = { 'bashls' },
  json = { 'jsonls' },
  jsonc = { 'jsonls' },
  yaml = { 'yamlls' },
  toml = { 'taplo' },
}

local function ensure_server(server)
  if vim.lsp.is_enabled(server) then return end
  -- Prefer a binary already on PATH (e.g. mise-managed gopls) over a Mason copy,
  -- so the version your dotfiles pin stays the one that's actually used.
  local cmd = vim.lsp.config[server] and vim.lsp.config[server].cmd
  if type(cmd) == 'table' and vim.fn.executable(cmd[1]) == 1 then
    vim.lsp.enable(server)
    return
  end
  local ok, registry = pcall(require, 'mason-registry')
  local pkg_name = require('mason-lspconfig').get_mappings().lspconfig_to_package[server]
  if not ok or not pkg_name or not registry.has_package(pkg_name) then return end
  local pkg = registry.get_package(pkg_name)
  if pkg:is_installed() then
    vim.lsp.enable(server)
  elseif not pkg:is_installing() then
    vim.notify('Installing LSP server: ' .. server .. ' …', vim.log.levels.INFO)
    pkg:install()
    pkg:on('install:success', function()
      vim.schedule(function() vim.lsp.enable(server) end)
    end)
  end
end

vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('kickstart-lazy-lsp', { clear = true }),
  callback = function(args)
    for _, server in ipairs(on_demand_servers[args.match] or {}) do
      ensure_server(server)
    end
  end,
})

-- vim: ts=2 sts=2 sw=2 et
