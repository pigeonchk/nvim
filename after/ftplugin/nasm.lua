-- some options to automatically format comments
vim.bo.formatoptions = 'croqanb1j'
-- only for comments, code can still go past it
vim.bo.textwidth = 80
-- set variable tabstops so that the comments always start at line 30
-- see :h 'vartabstop'
vim.bo.vartabstop = '4,30,4'
