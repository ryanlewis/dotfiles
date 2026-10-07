-- Filetype detection and highlighting for chezmoi source files (`*.tmpl`, dot_ names).
--  The tmp-buffer option makes `chezmoi edit` buffers detect the same way.
vim.g['chezmoi#use_tmp_buffer'] = 1
vim.pack.add { 'https://github.com/alker0/chezmoi.vim' }

-- vim: ts=2 sts=2 sw=2 et
